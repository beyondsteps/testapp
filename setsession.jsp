<?xml version="1.0" encoding="UTF-8" ?>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<%
	String key = null;
	String value = null;
	key = request.getParameter("key");
	value = request.getParameter("value");
	
	if(key!=null && value!=null)
		session.setAttribute(key, value);
%>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>javax.servlet.http.HttpSession setAttribute</title>
</head>
<body>
javax.servlet.http.HttpSession setAttribute
<form>
	key : <input type="text" title="key" name="key"/>
	value : <input type="text" title="value" name="value" />
	<input type="submit" value="submit"/>
</form>
</body>
</html>