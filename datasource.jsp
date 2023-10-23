<%@ page language="java" contentType="text/html;charset=euc-kr" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.*" %>
<%@ page import="javax.naming.*" %>

<html>
<head><title>DataSource Connection Test</title></head>
<body>

<%
      // Declare the JDBC objects.
      Context ctx = null;
      DataSource ds = null;
      Connection con = null;
      Statement pstmt = null;
      ResultSet rs = null;

      try {
         ctx = new InitialContext();
         ds =(DataSource) ctx.lookup("java:jboss/datasources/mysqlDs");
         con = ds.getConnection();
    
         // Create and execute an SQL statement that returns some data.
         String SQL = "SELECT * FROM Employees";
         pstmt = con.prepareStatement(sql);
         rs = pstmt.executeQuery();
    

         // Iterate through the data in the result set and display it.
         while (rs.next()) {
            out.println(rs.getString(1));
         }
      }

      // Handle any errors that may have occurred.
      catch (Exception e) {
         e.printStackTrace();
         out.println("Error!!!!");
      }
      finally {
         try{
		    rs.close();
		    pstmt.close();
			con.close();
			
		}catch(Exception ie){
			ie.printStackTrace();
		}
	}
%>


</body>
</html>
