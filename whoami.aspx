<%@Language="C#"%>
<html><head><title>Whoami Test Page</title><head>
<%
    string currentUser = Request.ServerVariables["LOGON_USER"];
    if (currentUser == "")
        currentUser = "anonymous";
    Response.Write(currentUser);
%> 
</html>