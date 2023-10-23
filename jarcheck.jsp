<%@ page import="java.util.*"%>


<%
    String reqName = null;
    java.net.URL classUrl = null;

    reqName = request.getParameter("reqName");
    if (reqName == null || reqName.trim().length() == 0) {
        reqName = "javax.servlet.http.HttpServlet";
    }
%>

<html>
<body onLoad="document.form1.reqButton.focus();">

<br><hr align=center><br>
[Example]<br>
Document Builder Factory - org.apache.xerces.jaxp.DocumentBuilderFactoryImpl<br>
SAX Parser Factory - org.apache.xerces.jaxp.SAXParserFactoryImpl<br>
Transformer Factory - org.apache.xalan.processor.TransformerFactoryImpl<br>
<br>
(ex) javax.servlet.http.HttpServlet<br>

<form action="jarcheck.jsp" name=form1>
<input type=text name="reqName" value="<%= reqName %>">
<input type=submit name=reqButton value="FIND">
</form>

<%
    if (reqName.trim().length() != 0) {
%>

[Search Result]
<br>
<%
 	reqName = reqName.replace('.', '/').trim();
	reqName = "/" + reqName + ".class";
        classUrl = this.getClass().getResource(reqName);
        if (classUrl == null) {
            out.println(reqName + " not found");
        } else {
            out.println("<b>" + reqName + "</b>: [" +
classUrl.getFile() + "]\n"
);
        }
        out.println("<br>");

    }
%>
