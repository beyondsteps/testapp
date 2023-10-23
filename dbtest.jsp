<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.*" %>
<%@ page import="javax.naming.*" %>
<%@ page import="javax.rmi.*" %>
<%@ page import="java.rmi.*" %>
<%
try{
        Context ctx=new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:jboss/datasources/mysqlDs");
        Connection con = ds.getConnection();
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("select 1"); 
        rs.next();
        out.println("Result is "+rs.getString(1));
        rs.close();
        con.close();
}catch(SQLException se){
        se.printStackTrace();
}
%>
