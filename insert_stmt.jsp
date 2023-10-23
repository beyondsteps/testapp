<%@page import="java.sql.Statement"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.DriverManager"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Insert title here</title>
</head>
<body>
<%
    String driverName="com.mysql.jdbc.Driver";
    String url = "jdbc:mysql://192.168.50.115:3306/mysql";
    String id = "root";
    String pwd ="wasadm";
    request.setCharacterEncoding("utf-8");
    String code = request.getParameter("code");
    String irum = request.getParameter("irum");
    String celphone = request.getParameter("celphone");
    
    Class.forName(driverName);
    Connection conn = DriverManager.getConnection(url,id,pwd);
    

    String sql = String.format("insert into info values('%s','%s','%s')", code, irum,celphone);
     
    Statement stmt = conn.createStatement();
    int r = stmt.executeUpdate(sql);
    
    if(r==1){
    out.println("1개 데이터 추가 성공");
    }
    stmt.close();
    conn.close();
%>
%</body>
%</html>
