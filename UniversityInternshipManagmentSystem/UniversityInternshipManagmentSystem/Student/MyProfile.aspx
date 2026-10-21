<%@ Page Language="C#" %>
<script runat="server">
    protected override void OnLoad(System.EventArgs e)
    {
        base.OnLoad(e);
        Response.Redirect(ResolveUrl("~/Student/StudentProfilePage/Profile.aspx"), false);
        Context.ApplicationInstance.CompleteRequest();
    }
</script>