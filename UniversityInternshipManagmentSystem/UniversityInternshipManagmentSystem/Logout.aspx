<%@ Page Language="C#" AutoEventWireup="true" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string query = Request.Url.Query ?? "";
        Response.Redirect("~/login/Logout.aspx" + query, false);
        Context.ApplicationInstance.CompleteRequest();
    }
</script>
<!DOCTYPE html>
<html>
<head runat="server">
    <title>Redirecting to Logout...</title>
</head>
<body>
</body>
</html>
