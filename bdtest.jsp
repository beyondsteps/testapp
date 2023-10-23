<%@ page contentType="text/html;charset=utf-8" session="true" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.sql.*" %>
<%@ page import="javax.naming.*" %>
<%@ page import="javax.rmi.*" %>
<%@ page import="java.rmi.*" %>

<%!
private boolean isDriverLoadedForURL(String url)
{

   try
   {
DriverManager.getDriver(url);
System.out.println("Driver already registered for url: " + url);
      return true;
   }
   catch (Exception e)
   {
System.out.println("Driver not yet registered for url: " + url);
      return false;
   }
}

%>
<%
      // Create a variable for the connection string.
      String connectionUrl = "http://192.168.50.115:8080/select_ds.jsp";
      String usr = "root";
      String pwd = "-4be3f0d7ffa0bbd3";

      // Declare the JDBC objects.
      Connection con = null;
      Statement stmt = null;
      ResultSet rs = null;
        String driverClass = "com.mysql.jdbc.Driver";

      try {

      Class clazz = Class.forName(driverClass, true, Thread.currentThread().getContextClassLoader());
System.out.println(">>>>"+isDriverLoadedForURL(connectionUrl ));

      Driver driver = (Driver) clazz.newInstance();
      DriverManager.registerDriver(driver);
System.out.println(">>>>"+isDriverLoadedForURL(connectionUrl ));
          
         
         // Establish the connection.
         Class.forName("com.mysql.jdbc.Driver");
	System.out.println("드라이버 로드 성공!!!!");
        System.out.println(DriverManager.getDriver(connectionUrl));

         con = DriverManager.getConnection(connectionUrl,usr,pwd);
    
         // Create and execute an SQL statement that returns some data.
         String SQL = "SELECT 1";
         stmt = con.createStatement();
         rs = stmt.executeQuery(SQL);
    

         // Iterate through the data in the result set and display it.
         while (rs.next()) {
            System.out.println(rs.getString(1));
         }
      }

      // Handle any errors that may have occurred.
      catch (Exception e) {
         e.printStackTrace();
      }
      finally {
         if (rs != null) try { rs.close(); } catch(Exception e) {}
         if (stmt != null) try { stmt.close(); } catch(Exception e) {}
         if (con != null) try { con.close(); } catch(Exception e) {}
      }
%>
