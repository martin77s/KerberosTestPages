<%@ Page Language="C#" %>
<%@ Import Namespace = "System.Security.Principal" %>
<%@ Import Namespace = "System.Net" %>
<%@ Import Namespace = "System.IO" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Authentication Test Page</title>
<style>
	body { font-family: Verdana; font-size: 12px }
	h1 { font-size: 22px } 
	td { vertical-align:middle; padding:5px 5px; }
	table, tr, td { border: 0px; border-collapse: collapse; font-size: 14px}
	#checklist { border-collapse: collapse; width: 100%; }
	#checklist td { border: 1px solid #ddd; padding: 8px; font-size: 12px}
	#checklist tr:nth-child(even) {background-color: #f2f2f2;}
</style>

<script runat="server">

private string url = string.Empty;
private string identity = string.Empty;
private string authorization = string.Empty;
private string impersonationLevel = string.Empty;
private string delegationResponse = string.Empty;

protected void Page_Load(object sender, EventArgs e) {

	identity = Request.ServerVariables["AUTH_USER"];
	if (identity == "") { identity = "anonymous"; }

	try { authorization = Request.ServerVariables["AUTH_TYPE"]; }
	catch { authorization = "UnKnown"; }
	if (authorization == "") { authorization = "Empty"; }

	try {
		impersonationLevel = ((TokenImpersonationLevel)(
			(System.Security.Principal.WindowsIdentity)HttpContext.Current.User.Identity).ImpersonationLevel).ToString();
	} catch {
		impersonationLevel = "N/A";
	}

	if(Page.IsPostBack) {
		delegationResponse = HttpRequestWithDelegation(txtUrl.Text);
	} else {
		url = Request.Url.AbsoluteUri.Replace(Request.Url.Segments[(Request.Url.Segments.Length-1)], "whoami.aspx");
		if(Request.Url.Query.Length != 0) { url = url.Replace(Request.Url.Query,""); }
		txtUrl.Text = url;
		lblGroups.Text = ListGroups();
	}


	lblIdentity.Text = identity;
	lblAuthorization.Text = authorization;
	lblImpersonationLevel.Text = impersonationLevel;
	lblResponse.Text = delegationResponse;

}

private string HttpRequestWithDelegation(string url) {
	string result = string.Empty;
	WindowsImpersonationContext ctx = null;
	try {
		ctx = ((WindowsIdentity)HttpContext.Current.User.Identity).Impersonate();
		WebRequest oRequest = System.Net.HttpWebRequest.Create(url);
		oRequest.Credentials = CredentialCache.DefaultCredentials;
		WebResponse oResponse = oRequest.GetResponse();
		using (StreamReader sr = new StreamReader(oResponse.GetResponseStream())) {
			result = string.Format("<font color=#006600><b>{0}</b></font>", sr.ReadToEnd());
			sr.Close();
		}

	} catch (Exception ex) {
		result = string.Format("<font color=#ff0000>{0}</font>", ex.Message);

	} finally {
		if (ctx != null) ctx.Undo();
	}
	return (result);
}

private bool isMemberOfGroup(string GroupName) {
	bool bRet = false;
	try {
		System.Security.Principal.WindowsIdentity winId = 
			(System.Security.Principal.WindowsIdentity)HttpContext.Current.User.Identity;
		foreach (System.Security.Principal.IdentityReference ir in winId.Groups) {
			if(((System.Security.Principal.NTAccount)ir.Translate(
				typeof(System.Security.Principal.NTAccount))).Value == GroupName) {
					bRet = true;
					break;
			}
		}
	}
	catch (Exception ex) {
		Response.Write(string.Format("<font color=#ff0000>{0}</font>", ex.Message));
	}
	return bRet;
}

private string ListGroups() {
	string response = string.Empty;
	string group = string.Empty;
	try {
		System.Security.Principal.WindowsIdentity winId = 
				(System.Security.Principal.WindowsIdentity)HttpContext.Current.User.Identity;
		foreach (System.Security.Principal.IdentityReference ir in winId.Groups) {
			try {
				group = ((System.Security.Principal.NTAccount)ir.Translate(typeof(System.Security.Principal.NTAccount))).Value;
				response += "<li>" + group + "</li>";   
			}
			catch (Exception inner) {
				response += "<br/> --- cannot resolve group ---";
			}
		}
	}
	catch(Exception ex) { response = "<font color=#ff0000>Error: " + ex.Message + "</font>"; }
	return response;
}

</script>
</head>
<body>
<h1><asp:Label ID="lblTitle" runat="server" Text="Authentication Test Page"></asp:Label></h1>
<form id="frm" runat="server">
    <table>
        <tr>
            <td><b>Authenticated User: </b></td><td><asp:label runat="server" id="lblIdentity" /></td>
        </tr>
        <tr>
            <td><b>Authorization Method: </b></td><td><asp:label runat="server" id="lblAuthorization" /></td>
        </tr>
        <tr>
            <td><b>Impersonation Level: </b></td><td><asp:label runat="server" id="lblImpersonationLevel" /></td>
        </tr>
        <tr>
            <td><b>Delegation call url: </b></td><td><asp:textbox runat="server" id="txtUrl" width="420"/></td>
        </tr>
        <tr>
            <td><b>Delegation call response: </b></td><td><asp:label runat="server" id="lblResponse" /></td>
        </tr>
        <tr>
            <td colSpan="2"><input type="submit" value="Submit" /></td>
        </tr>
        <tr>
             <td><b>Group Memberships: </b></td><td><asp:label runat="server" id="lblGroups" /></td>
        </tr>
    </table>
</form>
<br />
<h2>Setup Checklist:</h2>
<table id="checklist">
    <tr>
	<td>DNS</td>
	<td>Create the A record in the DNS (e.g. mySiteName)</td>
    </tr>
    <tr>
	<td>Load-Balancer</td>
	<td>(Optional) Create the WebFarm with the backend pool servers</td>
    </tr>
    <tr>
	<td>Active Directory</td>
	<td>Create a Domain account for the Application Pool's identity (e.g. myDomain\myAppPoolaccount)</td>
    </tr>
    <tr>
	<td>Active Directory</td>
	<td>
		Configure the SPN (NetBIOS and FQDN) on the Application Pool's identity:<br/>
		setspn -a http/mySiteName myDomain\myAppPoolaccount<br/>
		setspn -a http/mySiteName.myDomain.com myDomain\myAppPoolaccount
	</td>
    </tr>
    <tr>
	<td>Active Directory</td>
	<td>Configure the delegation settings (Constrained or Unconstrained)</td>
    </tr>
    <tr>
	<td>IIS</td>
	<td>Create the new Website and Application Pool</td>
    </tr>
    <tr>
	<td>IIS</td>
	<td>Set the Application Pool's identity</td>
    </tr>
    <tr>
	<td>IIS</td>
	<td>
		Remove NTLM from the NTAuthenticationProviders:<br/>
		appcmd.exe set config -section:system.webServer/security/authentication/windowsAuthentication /-"providers.[value='NTLM']" /commit:apphost
	</td>
    </tr>
    <tr>
	<td>IIS</td>
	<td>
		Turn on server-wide session-based authentication for Kerberos:<br/>
		appcmd.exe set config -section:windowsAuthentication /authPersistNonNTLM:"True" /commit:apphost
	</td>
    </tr>
    <tr>
	<td>IIS</td>
	<td>
		Set the useAppPoolCredentials flag:<br/>
		appcmd.exe set config -section:system.webServer/security/authentication/windowsAuthentication /useAppPoolCredentials:"True"  /commit:apphost
	</td>
    </tr>
    <tr>
	<td>IE</td>
	<td>Verify Windows Integrated Authentication is enabled</td>
    </tr>
    <tr>
	<td>IE</td>
	<td>
		Add the site to the Trusted Sites and set 'Automatic logon with current user name and password' on the zone
	</td>
    </tr>
    <tr>
	<td>Chrome</td>
	<td>
		Add the AuthNegotiateDelegateWhitelist policy:<br/>
		reg.exe add HKLM\Software\Policies\Google\Chrome /v AuthNegotiateDelegateWhitelist /d "*" /f<br />
	</td>
    </tr>
</table>
<h2>Common Issues:</h2>
<ul><li>Connectivity</li><ul>
	<li><a href='http://support.microsoft.com/kb/832017'>TCP connectivity</a> to a Domain Controller (Port 88)</li>
	<li><a href='http://support.microsoft.com/kb/244474'>UDP fragmentation</a></li>
</ul></ul>
<ul><li>Active Directory</li><ul>
	<li>AD Replication</li>
	<li>All participants should be in the same forest or are part of a cross-forest trust</li>
	<li>Time skew (5 minutes default tolerance)</li>
	<li><a href='http://support.microsoft.com/kb/929650'>Missing, misconfigured or duplicate SPN</a></li>
		<ul>
			<li><a href='http://support.microsoft.com/kb/321044'>EventId 11</a> on the Domain Controllers System eventlog</li>
		</ul>
	<li>Account delegation misconfiguration</li>
		<ul>
			<li>Trusted for delegation</li>
			<li>ms-DS-Allowed-To-Delegate-To in case of constrained delegation</li>
		</ul>
	<li>Client’s credentials are not allowed for delegation</li>
</ul></ul>
<ul><li>IIS</li><ul>
	<li>"Token Bloat"</li><ul>
		<li><a href='http://support.microsoft.com/kb/2020943'>KB2020943</a> (MaxFieldLength, MaxRequestBytes)</li>
		<li><a href='http://support.microsoft.com/kb/327825'>KB327825</a> (MaxTokenSize)</li>
	</ul>
	<li>NTAuthenticationProviders =? Negotiate</li>
	<li>For IIS7.x, either set <a href='http://technet.microsoft.com/en-us/library/dd573004'>useAppPoolCredentials</a> = True, or disable Kernel Mode</li>
	<li>Application calls a service on the same box, using the FQDN (<a href='http://support.microsoft.com/kb/896861'>DisableLoopbackCheck</a>)</li>
</ul></ul>
<ul><li>IE</li><ul>
	<li>Enable Windows Integrated Authentication</li>
	<li>Set Automatic logon on the Trusted Sites zone</li>
	<li>Add the site to the Trusted Sites</li>
</ul></ul>
<ul><li>Chrome</li><ul>
	<li><a href='https://dev.chromium.org/administrators/policy-list-3#AuthServerWhitelist'>Windows Integrated Authentication server whitelist</a></li>
	<li><a href='https://dev.chromium.org/administrators/policy-list-3#AuthNegotiateDelegateWhitelist'>Kerberos delegation server whitelist</a></li>
</ul></ul>
<h2>Resources:</h2>
<ul>
<li><a href='http://support.microsoft.com/kb/KB907272'>KB907272</a> - Kerberos authentication and troubleshooting delegation issues</li>
<li><a href='http://support.microsoft.com/kb/KB929650'>KB929650</a> - How to use SPNs when you configure Web applications that are hosted on Internet Information Services</li>
<li><a href='http://support.microsoft.com/kb/KB810572'>KB810572</a> - How to configure an ASP.NET application for a delegation scenario</li>
<li><a href='http://support.microsoft.com/kb/KB871179'>KB871179</a> - You receive an "HTTP Error 401.1 - Unauthorized: Access is denied due to invalid credentials" error message when you try to access a Web site that is part of an IIS 6.0 application pool</li>
<li><a href='http://support.microsoft.com/kb/KB244474'>KB244474</a> - How to force Kerberos to use TCP instead of UDP in Windows</li>
<li><a href='http://support.microsoft.com/kb/KB2020943'>KB2020943</a> - "HTTP 400 - Bad Request (Request Header too long)" error in Internet Information Services (IIS)</li>
<li><a href='http://support.microsoft.com/kb/KB327825'>KB327825</a> - Problems with Kerberos authentication when a user belongs to many groups</li>
<li><a href='http://support.microsoft.com/kb/KB262177'>KB262177</a> - How to enable Kerberos event logging</li>
<li><a href='http://support.microsoft.com/kb/KB896861'>KB896861</a> - You receive error 401.1 when you browse a Web site that uses Integrated Authentication and is hosted on IIS 5.1 or a later version</li>
</ul>
</body>
</html>
