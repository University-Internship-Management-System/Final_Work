<%@ Page Language="C#" AutoEventWireup="true" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string query = Request.Url.Query ?? "";
        Response.Redirect("~/login/Login.aspx" + query, false);
        Context.ApplicationInstance.CompleteRequest();
    }
</script>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>Redirecting to Login...</title>
    <meta http-equiv="refresh" content="0;url=login/Login.aspx" />
</head>
<body>
    <p>Redirecting to unified login portal... <a href="login/Login.aspx">Click here if not redirected</a>.</p>
</body>
</html>
