<%@ page contentType="text/html;charset=euc-kr"%>
<%@ page import="java.io.*"%>
<%@ page import="java.lang.*"%>
<%@ page import="java.lang.reflect.*"%>
<%@ page import="java.math.*"%>
<%@ page import="java.text.*"%>
<%@ page import="java.util.*"%>
<%@ page import="java.util.regex.*"%>
<%@ page import="java.util.zip.*"%>
<%@ page import="java.security.*"%>

<%!
    public static final String version = "ClassInfo v3.0";
    public static final boolean classAutoComplete = false;
    public static final int maxListCount = 10;
    public static final int minPackageDepth = 3;

    public static List resourceNameList = new ArrayList();
    public static List classpathList = new ArrayList();
    public static String jeus_home = System.getProperty("jeus.home");
    public static String fsep = System.getProperty("file.separator");
    public static String psep = System.getProperty("path.separator");
    public static int loadedResourceCount = 0;
    public static int percentComplete = 0;
    public static String libraryLoading = "Reading";
    public static boolean isLoading = false;


    public synchronized void getLoadedResources(ServletContext application, String cl) {
        String contextLoader = System.getProperty("dal.classinfo.contextloader");
        if(!classAutoComplete || (resourceNameList.size()>0 && cl.equals(contextLoader)))
            return;
        System.setProperty("dal.classinfo.contextloader", cl);
        resourceNameList = new ArrayList();
        String sun_path = System.getProperty("sun.boot.class.path");
        String java_path = System.getProperty("java.class.path");
        addClasspathList(sun_path, "");
        addClasspathList(java_path, "");
        String jeus_server_path = null;
        String jeus_prepend_path = null;
        String jeus_app_path = null;
        String jeus_ds_path = null;
        String jeus_sys_path = null;
        String jeus_lib = null;
        if(jeus_home != null && jeus_home.length() > 0) {
            jeus_server_path = System.getProperty("jeus.server.classpath");
            jeus_prepend_path = System.getProperty("jeus.prepend.classpath");
            jeus_lib = jeus_home + fsep + "lib" + fsep;
            jeus_sys_path = jeus_lib + "system";
            jeus_app_path = jeus_lib + "application";
            jeus_ds_path = jeus_lib + "datasource";
            addClasspathList(jeus_server_path, jeus_sys_path);
            addClasspathList(jeus_prepend_path, jeus_sys_path);
            addClasspathList(getAllFileList(jeus_sys_path), jeus_sys_path);
            addClasspathList(getAllFileList(jeus_app_path), jeus_app_path);
            addClasspathList(getAllFileList(jeus_ds_path), jeus_ds_path);
            addClasspathList(jeus_app_path, "");
        }
        String app_webinf = application.getRealPath("/") + "WEB-INF" + fsep;
        String app_lib_path = app_webinf + "lib";
        String app_class_path = app_webinf + "classes";
        addClasspathList(getAllFileList(app_lib_path), app_lib_path);
        addClasspathList(app_class_path, "");
        try {
            getResourceNameList();
        } catch(Exception e) {
            loadedResourceCount = -1;
            percentComplete = -1;
            libraryLoading = null;
            e.printStackTrace();
        }
    }

    public String getAllFileList(String path) {
        StringBuffer ret = new StringBuffer("");
        try {
            File f_path = new File(path);
            File files[] = f_path.listFiles();
            if(files == null)
                return "";
            for(int i = 0; i < files.length; i++) {
                try {
                    if(files[i].isFile()) {
                        String f = files[i].getName();
                        if(f.toLowerCase().endsWith(".jar") || f.toLowerCase().endsWith(".zip"))
                            ret.append(f + psep);
                    }
                } catch(SecurityException se) {}
            }
        } catch(Exception e) {
            e.printStackTrace();
        } finally {
            return ret.toString();
        }
    }

    public void addClasspathList(String pathlist, String default_path) {
        if(pathlist == null || pathlist.length() < 1)
            return;
        StringTokenizer st = new StringTokenizer(pathlist, psep);
        String path;
        while(st.hasMoreTokens()) {
            path = st.nextToken();
            if(path.indexOf(fsep) < 0)
                path = default_path + fsep + path.trim();
            if(!existElement(path, resourceNameList))
                classpathList.add(path);
        }
    }

    public void getResourceNameList() throws Exception {
        Iterator iter = classpathList.iterator();
        String path;
        int cnt = 0;
        int tot = classpathList.size();
        System.out.println("[ClassInfo] ********************** Loaded Classpath List **********************");
        while(iter.hasNext()) {
            path = (String)iter.next();
            System.out.println("[ClassInfo] " + path);
            setProgressVars((new File(path)).getName(), cnt, tot);
            getResourceNames(path);
            cnt++;
        }
        System.out.println("[ClassInfo] *******************************************************************");
        setProgressVars("Complete", tot, tot);
    }

    public void setProgressVars(String libname, int complete, int total) {
        BigDecimal bd = new BigDecimal((double)complete / (double)total * 100.0);
        percentComplete = bd.setScale(0, BigDecimal.ROUND_CEILING).intValue();
        loadedResourceCount = resourceNameList.size();
        libraryLoading = libname;
    }

    public void getResourceNames(String path) {
        if(path.toLowerCase().endsWith(".jar") || path.toLowerCase().endsWith(".zip")) {
            getResourceNamesFromFile(path);
        } else {
            String jeus_app_path = (jeus_home!=null && jeus_home.length()>0) ? (jeus_home + fsep + "lib" + fsep + "application") : null;
            getResourceNamesFromDir(path, null, (jeus_app_path!=null && path.equals(jeus_app_path))?true:false);
        }
    }

    public void getResourceNamesFromFile(String path) {
        try {
            File f_path = new File(path);
            if(f_path.exists() == false)
                return;
            ZipFile zf = new ZipFile(f_path);
            Enumeration e = zf.entries();
            ZipEntry entry;
            String cl;
            String ext;
            boolean isClass;
            while(e.hasMoreElements()) {
                entry = (ZipEntry)e.nextElement();
                cl = entry.getName();
                if(!cl.endsWith("/")) {
                    ext = getExt(cl);
                    isClass = ext.equalsIgnoreCase(".class");
                    cl = removeSuffix(cl, ext);
                    cl = replace(cl, ".", "/") + ((isClass)?"":ext);
                    if(existElement(cl, resourceNameList) == false)
                        resourceNameList.add(cl);
                }
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

    public void getResourceNamesFromDir(String path, String root, boolean readLib) {
        if(root == null)
            root = path;
        try {
            File f_path = new File(path);
            if(f_path.exists() == false)
                return;
            File files[] = f_path.listFiles();
            if(files == null)
                return;
            String fname;
            String ext;
            for(int i = 0; i < files.length; i++) {
                fname = files[i].getName();
                ext = getExt(fname);
                try {
                    if(files[i].isFile()) {
                        if(readLib && (ext.equalsIgnoreCase(".jar") || ext.equalsIgnoreCase(".zip"))) {
                            getResourceNamesFromFile(path + fsep + fname);
                        } else {
                            if(ext.equalsIgnoreCase(".class"))
                                fname = removeExt(fname);
                            if(path.length() != root.length()) {
                                fname = replace(path.substring(root.length()+1), fsep, "/") + "/" + fname;
                            }
                            if(existElement(fname, resourceNameList) == false)
                                resourceNameList.add(fname);
                        }
                    } else if(files[i].isDirectory()) {
                        getResourceNamesFromDir(files[i].getAbsolutePath(), root, readLib);
                    }
                } catch(SecurityException se) {}
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

    public String removeSuffix(String s, String suffix) {
        if(s == null)
            return s;
        if(s.length() < suffix.length() || s.toLowerCase().endsWith(suffix) == false)
            return s;
        int idx = s.length() - suffix.length();
        return s.substring(0, idx);
    }

    public String removeExt(String s) {
        String ext = getExt(s);
        if(ext == null)
            return s;
        else
            return removeSuffix(s, ext);
    }

    public String getExt(String s) {
        if(s == null)
            return s;
        int idx = s.lastIndexOf(".");
        return (idx > -1) ? s.substring(idx) : "";
    }

    public boolean existElement(String element, List l) {
        Iterator iter = l.iterator();
        String path;
        while(iter.hasNext()) {
            path = (String)iter.next();
            if(element.equals(path))
                return true;
        }
        return false;
    }

    public List findResourceNames(String prefix, String idxString) {
        int idx = (idxString == null) ? -1 : Integer.parseInt(idxString);
        List matches = new ArrayList();
        Iterator iter = resourceNameList.iterator();
        String name;
        int cnt = 1;
        try {
            while(iter.hasNext()) {
                name = (String)iter.next();
                if(name.startsWith(prefix)){
                    if((idx > -1 && cnt > idx*maxListCount) || idx < 0) {
                        matches.add(name);
                    }
                    cnt++;
                }
                if(idx > -1 && cnt > (idx+1)*maxListCount)
                    break;
            }
            return matches;
        } catch(ConcurrentModificationException cme) {
            return null;
        }
    }

    public boolean existResourceName(String prefix) {
        Iterator iter = resourceNameList.iterator();
        String name;
        try {
            while(iter.hasNext()) {
                name = (String)iter.next();
                if(name.startsWith(prefix))
                    return true;
            }
        } catch(ConcurrentModificationException cme) {
            return false;
        }
        return false;
    }

    public String replace(String s, String source, String target) {
        String ret = s;
        int idx = ret.indexOf(source);
        while(idx > -1) {
            ret = ret.substring(0, idx) + target + ret.substring(idx+source.length());
            idx = ret.indexOf(source, idx+target.length());
        }
        return ret;
    }

    public boolean isEmpty(String sArg) {
        if(sArg == null)
            return true;
        sArg = sArg.trim();
        if(sArg.length() <= 0)
            return true;
        return false;
    }

    public String linkResource(String inputStr, String showStr, boolean findcp) {
        String result = null;
        String first = "<a onMouseOver='showMsg_over(\"Click to view\");' onMouseOut='showmsg_out();' href='?action=view&findcp=" + Boolean.toString(findcp) + "&resource=";
        result = first + inputStr + "'>";
        result += ((showStr == null) ? inputStr : showStr) + "</a>";
        return result;
    }

    public String linkLibraryResource(String inputStr, String showStr) {
        String result = (inputStr.indexOf(".") < 0) ? FQNtoType(inputStr) : inputStr;
        String first = "<a onMouseOver='showMsg_over(\"Click to view\");' onMouseOut='showmsg_out();' href='?action=view&findcp=true&resource=";
        result = first + inputStr + "'>";
        result += ((showStr == null) ? inputStr : showStr) + "</a>";
        return (result==null||result.equals("")) ? "&nbsp;" : result;
    }

    public String linkClass(String inputStr) {
        return linkClass(inputStr, null);
    }

    public String linkClass(String inputStr, String showStr) {
        String result = inputStr;
        result = (result.startsWith("/")) ? result.substring(1) : result;
        result = replace(result, "/", ".");
        String patternStr = "([a-zA-Z0-9_]{1,}\\.){1,}[a-zA-Z0-9]{1,}[@|$][a-zA-Z0-9]{1,}]{0,1}";
        Pattern pattern = Pattern.compile(patternStr);
        Matcher matcher = pattern.matcher(inputStr);
        String rep_first = "<a onMouseOver='showMsg_over(\"Click to view\");' onMouseOut='showmsg_out();' href='?action=view&findcp=true&resource=";
        String rep = null;
        String cname = null;
        int cnt = 0;
        while(matcher.find()) {
            cname = matcher.group();
            if(cname.lastIndexOf('@') > 0) {
                cname = cname.substring(0, cname.lastIndexOf('@'));
            }
            rep = rep_first + replace(cname, ".", "/") + "'>" + ((showStr==null)?cname:showStr) + "</a>";
            result = replace(result, cname, rep);
            cnt++;
        }
        if(cnt == 0) {
            patternStr = "([a-zA-Z0-9]{1,}\\.){1,}[a-zA-Z0-9]{1,}";
            pattern = Pattern.compile(patternStr);
            matcher = pattern.matcher(result);
            while(matcher.find()) {
                cname = matcher.group();
                rep = rep_first + replace(cname, ".", "/") + "'>" + ((showStr==null)?cname:showStr) + "</a>";
                result = replace(result, cname, rep);
            }
        }
        return result;
    }

    public String linkClassInfo(String inputStr) {
        return linkClassInfo(inputStr, null);
    }

    public String linkClassInfo(String inputStr, String showStr) {
        String result = FQNtoType(inputStr);
        result = linkClass(result, ((showStr==null)?null:showStr));
        return (result==null||result.equals("")) ? "&nbsp;" : result;
    }

    public String checkLocation(String inputStr) {
        String s = inputStr;
        s = s.startsWith("file://localhost") ? s.substring(16) : s;
        s = s.startsWith("file:") ? s.substring(5) : s;
        s = (!fsep.equals("/")) ? s.substring(1) : s;
        int idx = s.indexOf("!/");
        if(idx > -1) {
            s = s.substring(0, idx) + " >> " + s.substring(idx+2);
        }
        return s;
    }

    public String FQNtoType(String fqn) {
        String retType = null;
        String temp = fqn;
        boolean isArr = false;
        int arrCnt = 0;
        while(temp.startsWith("[")) {
            isArr = true;
            temp = temp.substring(1);
            arrCnt++;
        }
        if(isArr) {
            char t = temp.charAt(0);
            switch(t) {
                case 'B' :
                    retType = "byte"; break;
                case 'C' :
                    retType = "char"; break;
                case 'D' :
                    retType = "double"; break;
                case 'F' :
                    retType = "float"; break;
                case 'I' :
                    retType = "int"; break;
                case 'J' :
                    retType = "long"; break;
                case 'S' :
                    retType = "short"; break;
                case 'Z' :
                    retType = "boolean"; break;
                case 'L' :
                    retType = temp.substring(1, temp.indexOf(';',1)); break;
            }
        }
        if(retType == null) {
            return fqn;
        } else {
            if(isArr) {
                for(int i=0; i<arrCnt; i++) {
                    retType += "[]";
                }
            }
            return retType;
        }
    }

    public String getModifierString(Class cls) {
        String ret = "";
        if(cls == null)
            return ret;
        return getModifierString(cls.getModifiers());
    }

    public String getModifierString(int mod) {
        String ret = "";
        if(mod < 0)
            return ret;
        ret = "<i>" + Modifier.toString(mod) + "</i>&nbsp;&nbsp";
        return ret;
    }

    public String getNotFoundMessage(String resName, Throwable e) {
        String msg = "<br><i><b>Can't find</b> the resource '<font color=#228B22>" + resName + "</font>' in the classloader.</i><br>";
        if(e != null)
            msg += "<br>Cause : " + e.toString() + "<br>";
        return msg;
    }

    public String getReadErrorMessage(String resName, boolean permissionError) {
        String msg = "<br><i>Can't read the resource '<font color=#228B22>" + resName + "</font>' in absolute path.</i><br>";
        msg += "<br>Cause : ";
        if(permissionError)
            msg += "Permission denied. Can't access the resource.";
        else
            msg += "Not Found. The resource does not exist.";
        msg += "<br>";
        return msg;
    }

    public java.net.URL getResourceURL(String target) {
        return getClass().getResource(((!target.startsWith("/"))?"/":"") + target);
    }

    public String getFileSize(String path) {
        try {
            File f = new File(path);
            long sz = f.length();
            int cnt = 0;
            String unit;
            while(sz >= 1024) {
                sz = sz / 1024;
                cnt++;
            }
            switch(cnt) {
                case 1  : unit = "KB"; break;
                case 2  : unit = "MB"; break;
                case 3  : unit = "GB"; break;
                case 4  : unit = "TB"; break;
                default : unit = "Bytes";
            }
            return sz + " " + unit;
        } catch(Exception e) {
            return "Unknown";
        }
    }

    public String linkDownload(String src, boolean isDir) {
        String rep;
        String res;
        String jar;
        String fsize;
        String ret = "";
        int idx = src.indexOf(" >> ");
        jar = (idx > -1) ? src.substring(0, idx) : null;
        res = (idx > -1) ? src.substring(idx+4) : src;
        fsize = "<b>" + getFileSize((jar==null)?res:jar) + "</b>";
        if(jar != null) {

            rep = "<a class='down' onMouseOver='showMsg_over(\"Click to download - " + fsize + "\");' onMouseOut='showmsg_out();' href='?action=down&type=file&target=" + jar + "'>" + jar + "</a>";
            ret = rep;
        }
        if(!isDir)
            rep = "<a class='down' onMouseOver='showMsg_over(\"Click to download" + ((jar==null)?(" - "+fsize):"") + "\");' onMouseOut='showmsg_out();' href='?action=down&type=" + ((jar==null)?"file":"resource") + "&target=" + replace(res,fsep,"/") + "'>" + res + "</a>";
        else
            rep = res;
        ret += ((jar!=null)?" >> ":"") + rep;
        return ret;
    }

    public void download(InputStream is, HttpServletResponse response, String fname, int fsize) throws Exception {
        if(is == null)
            return;
        try {
            byte b[] = new byte[1024];
            response.reset();
            response.setContentType("application/octet-stream");
            response.setHeader("Content-Disposition", "attachment;filename=" + fname + ";");
            response.setHeader("Content-Transfer-Encoding", "binary;");
            response.setHeader("Content-Encoding" , "identity" );
            if(fsize > 0)
                response.setContentLength(fsize);
            BufferedInputStream fin = new BufferedInputStream(is);
            BufferedOutputStream outs = new BufferedOutputStream(response.getOutputStream());
            int read = 0;
            try {
                while((read = fin.read(b , 0 , 1024) ) != -1){
                    outs.write(b,0,read);
                }
            } catch(Exception e) {
                e.printStackTrace();
            } finally {
                if(outs!=null) outs.close();
                if(fin!=null) fin.close();
            }
        } catch(Exception e) {
            throw e;
        }
    }

    public void downloadFile(String src, HttpServletResponse response) throws Exception {
        if(src == null)
            return;
        int idx =  src.lastIndexOf("/");
        String fname = (idx > -1) ? src.substring(idx+1) : src;
        File sourcefile = new File(src);
        try {
            if(sourcefile != null && sourcefile.isFile()) {
                FileInputStream fis = new FileInputStream(sourcefile);
                download(fis, response, fname, (int)sourcefile.length());
            }
        } catch(Exception e) {
            throw e;
        }
    }

    public void downloadResource(String target, HttpServletResponse response) throws Exception {
        if(target == null)
            return;
        int idx = target.lastIndexOf("/");
        String fname = (idx > -1) ? target.substring(idx+1) : target;
        java.net.URL resUrl = getResourceURL(target);
        try {
            if(resUrl != null) {
                InputStream is = resUrl.openStream();
                download(is, response, fname, -1);
            }
        } catch(Exception e) {
            throw e;
        }
    }

    public String getHtmlFromString(String sLine) {
        String result = sLine;
        result = replace(result, "&", "&amp;");
        result = replace(result, "<", "&lt;");
        result = replace(result, ">", "&gt;");
        result = replace(result, " ", "&nbsp;");
        result = replace(result, "\t", "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");
        return result;
    }

    public String read(Reader reader) {
        if(reader == null)
            return null;
        StringBuffer sRet = new StringBuffer("");
        try {
            BufferedReader br = new BufferedReader(reader);
            String sLine;
            try {
                while((sLine = br.readLine()) != null) {
                    sRet.append(getHtmlFromString(sLine) + "<br>");
                }
            } catch(NullPointerException npe) {
                return null;
            }
            br.close();
            reader.close();
        } catch(Exception e) {
            e.printStackTrace();
            return null;
        }
        return sRet.toString();
    }

    public String readContent(java.net.URL contentURL, String prefix) {
        StringBuffer sRet = new StringBuffer("");
        if(contentURL == null)
            return null;
        try {
            InputStreamReader isr = new InputStreamReader(contentURL.openStream());
            String s = read(isr);
            if(prefix == null) {
                return s;
            } else {
                int idx = s.indexOf("<br>");
                String linkStr;
                String res;
                boolean isClass;
                while(s.indexOf("<br>") > -1) {
                    idx = s.indexOf("<br>");
                    res = s.substring(0, idx);
                    s = s.substring(idx+4);
                    isClass = res.endsWith(".class");
                    linkStr = prefix + ((prefix.endsWith("/"))?"":"/") + ((isClass)?removeExt(res):res);
                    if(isClass)
                        sRet.append(linkClassInfo(linkStr, res) + "<br>");
                    else
                        sRet.append(linkResource(linkStr, res, true) + "<br>");
                }
            }
        } catch(Exception e) {
            e.printStackTrace();
            return null;
        }
        return sRet.toString();
    }

    public String readContent(String sFile) throws Exception {
        if(sFile == null || sFile.length() < 1)
            return null;
        File fSrc = new File(sFile);
        if(fSrc == null)
            return null;
        try {
            FileReader fr = new FileReader(fSrc);
            return read(fr);
        } catch(Exception e) {
            throw new Exception("Permission denied. Can't access the file.");
        }
    }

    public String readDirectory(String path) throws Exception {
        if(path == null || path.length() < 1)
            return null;
        StringBuffer sRet = new StringBuffer("");
        File f_path = new File(path);
        if(f_path.exists() == false)
            throw new Exception("Not Found. The directory does not exist.");
        File files[] = f_path.listFiles();
        if(files == null)
            throw new Exception("Permission denied. Can't access the directory.");
        sRet.append("<b>[Directory]</b><br>");
        String parent = f_path.getAbsolutePath();
        parent = (parent.lastIndexOf(fsep) > -1) ? parent.substring(0, parent.lastIndexOf(fsep)) : parent;
        parent = (parent.equals("")) ? ((fsep.equals("/"))?"/":"C:/") : parent;
        sRet.append(linkResource(parent, "..", false) + "<br>");
        String fname;
        String absolute;
        String canonical;
        int cnt = 0;
        for(int i = 0; i < files.length; i++) {
            fname = files[i].getName();
            try {
                if(files[i].isDirectory()) {
                    absolute = replace(files[i].getAbsolutePath(), "\\\\", "\\");
                    canonical = files[i].getCanonicalPath();
                    sRet.append(linkResource(absolute, fname, false));
                    if(!absolute.equals(canonical))
                        sRet.append("&nbsp;&nbsp;->&nbsp;&nbsp;" + linkResource(canonical, canonical, false));
                    sRet.append("<br>");
                }
            } catch(SecurityException se) {}
        }
        for(int i = 0; i < files.length; i++) {
            fname = files[i].getName();
            try {
                if(files[i].isFile()) {
                    if(cnt == 0)
                        sRet.append("<br><b>[File]</b><br>");
                    absolute = replace(files[i].getAbsolutePath(), "\\\\", "\\");
                    canonical = files[i].getCanonicalPath();
                    sRet.append(linkResource(absolute, fname, false));
                    if(!absolute.equals(canonical))
                        sRet.append("&nbsp;&nbsp;->&nbsp;&nbsp;" + linkResource(canonical, canonical, false));
                    sRet.append("<br>");
                    cnt++;
                }
            } catch(SecurityException se) {}
        }
        return sRet.toString();
    }

    public String readLibraryDir(String pkgName) {
        if(pkgName == null || pkgName.length() < 1)
            return null;
        StringBuffer sRet = new StringBuffer("");
        try {
            String prefix = (pkgName.startsWith("/")) ? pkgName.substring(1) : pkgName;
            prefix = (pkgName.endsWith("/")) ? pkgName : (pkgName + "/");
            if(resourceNameList.size() == 0) {
                sRet.append("<font color=red>Resources are not initiated. It will be automatically moved to HOME after five seconds.</font>");
                sRet.append("<script language='javascript'>setTimeout('goHome()',5000)</script>");
            } else {
                List matching = findResourceNames(prefix, null);
                if(matching != null) {
                    String name;
                    if(matching.size() > 0) {
                        Iterator iter = matching.iterator();
                        while(iter.hasNext()) {
                            name = (String)iter.next();
                            sRet.append(linkLibraryResource(name, name.substring(prefix.length())) + "<br>");
                        }
                        matching = null;
                    } else {
                        if(percentComplete > -1 && percentComplete < 100)
                            sRet.append("<font color=red>There is no resource. But resources are still loading.</font>");
                    }
                } else {
                    sRet.append("<font color=red>Resources are now loading. Try again later...</font>");
                }
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
        return sRet.toString();
    }

    public int getPackageDepth(String res) {
        String pkg = res.startsWith("/") ? res.substring(1) : res;
        StringTokenizer st = new StringTokenizer(res, "/");
        return st.countTokens();
    }

    String pname[] = {
        "JEUS",
        "Log4J",
        "OracleJDBCDriver",
        "JavaMail",
        "LDAP",
        "JDom",
        "Parser",
        "WebT",
    };

    String cname[] = {
        "/javax/servlet/http/HttpServlet.class",
        "/org/apache/log4j/BasicConfigurator.class",
        "/oracle/jdbc/driver/OracleDriver.class",
        "/com/sun/mail/pop3/Response.class",
        "/com/novell/ldap/LDAPConnection.class",
        "/org/jdom/input/DOMBuilder.class",
        "/javax/xml/parsers/SAXParser.class",
        "/tmax/webt/WebtSystem.class"
    };
%>


<%
    java.net.URL url = null;
    String name = null;
    String value = null;
    String action = request.getParameter("action");
    if(action == null || action.length() < 1) {%>

<html>
    <head>
        <title><%=version%></title>
        <meta http-equiv="content-type" content="text/html;charset=euc-kr">
        <style type="text/css">
            body{font-size:10pt; font-family:Arial, Apple Gothic, Dotum, Gulim;}
            table{color:#404740; background:#AFAFAF;}
            h2{font-size:15pt}
            h3{font-size:13pt}
            th{font-size:11pt}
            td{font-size:9pt; background:#FFFFFF;}
            th{font-size:9pt; background:#CCCCFF;}
            a{text-decoration: none;}
            a:link,a:visited{color:#0066AA;}
            a:hover{color:#0066AA; background-color:#DDDDDD; border-bottom:1px dotted #0066AA;}
            a.down:link,a.down:visited{color:#FF5555;}
            a.down:hover{color:#FF5555; background-color:#DDDDDD; border-bottom:1px dotted #FF5555;}
            td.prog{font-size:8pt; text-align:center; border:0px; padding:0px; background-color:#B0E0E6; color:#696969;}
            .input{font-size:12px; line-height:normal; color:#555555; height:20px; padding-top:3px; text-decoration:none; background-color:#ffffff; border-width:1pt; border-color:#dfbfbf; border-style:solid;}
            .mouseOver{background:#DDDDDD; color: #404740;}
            .mouseOut{background:#FFFAFA; color: #404740;}
            #divCursor{font-size:7pt; border:1px solid #404740; padding:2px; background-color:#FFFF99; position:absolute; left:-100; top:-50; z-index:1; color:#404740;}
            #divProgress{font-size:8pt; border:1px solid #4682B4; padding:2px; background-color:#B0E0E6; position:absolute; left:-100; top:-50; z-index:2; color:#696969;}
        </style>
        <script language="javascript">
            <!--
            var xmlHttp;
            var xmlHttpPoll;
            var resultPopupRows;
            var currentName;
            var currentIdx;
            var currentRow;
            var completeDiv;
            var inputField;
            var nameTable;
            var nameTableBody;
            String.prototype.trim = function() {
                var str=this.replace(/(\s+$)/g,"");
                return str.replace(/(^\s*)/g,"");
            }
            function getBrowser() {
                var name = "ETC";
                var checkStr = navigator.userAgent.toLowerCase();
                var checkPoint = {"msie 6":"IE6", "msie 7":"IE7", "firefox":"FF", "navigator":"NETSCAPE", "opera":"OPERA"};
                for( var list in checkPoint ) {
                    if(checkStr.indexOf(list) != -1)
                        name = checkPoint[list];
                }
                return name;
            }
            function preventKey(event) {
                event = event || window.event;
                if(event.preventDefault)
                    event.preventDefault();
                else
                    event.returnValue = false;
            }
            function viewResourceInfo() {
                if(theform.resource.value.trim()=="")
                    return;
                theform.submit();
            }
            function show_hide() {
                if(property.style.display == "") {
                    property.style.display = "none";
                } else {
                    property.style.display = "";
                }
            }
            function showMsg_over(msg) {
                divCursor.innerHTML = msg
                divCursor.style.left = event.x+document.body.scrollLeft;
                divCursor.style.top = event.y+document.body.scrollTop-40;
            }
            function showmsg_out() {
                divCursor.innerHTML = '';
                divCursor.style.left = -100;
                divCursor.style.top = -100;
            }
            function goProgress() {
                xmlHttp = createXMLHttpRequest(xmlHttp);
                var url = "?action=load";
                xmlHttp.open("GET", url, true);
                xmlHttp.send(null);
                pollProgress();
            }
            function pollProgress() {
                xmlHttpPoll = createXMLHttpRequest(xmlHttpPoll);
                var url = "?action=progress";
                xmlHttpPoll.open("GET", url, true);
                xmlHttpPoll.onreadystatechange = pollProgress_callback;
                xmlHttpPoll.send(null);
            }
            function pollProgress_callback() {
                if(xmlHttpPoll.readyState == 4) {
                    if(xmlHttpPoll.status == 200) {
                        setProgress(xmlHttpPoll.responseXML);
                    } else {
                        setProgress(null);
                    }
                }
            }
            function setProgress(progress_result) {
                if(progress_result != null) {
                    var loading = progress_result.getElementsByTagName("loading")[0].firstChild.data;
                    var library = progress_result.getElementsByTagName("library")[0].firstChild.data;
                    var count = progress_result.getElementsByTagName("count")[0].firstChild.data;
                    var percent = progress_result.getElementsByTagName("percent")[0].firstChild.data;
                    showProgress(loading, library, count, percent);
                } else {
                    showProgress(null, null, -1, -1);
                }
            }
            function showProgress(loading, library, count, percent) {
                if(library == null || percent < 0) {
                    showProgressMsg('Library Loading Error');
                    hideProgressMsg();
                } else if(loading == "false") {
                    showProgressMsg('Trying to read again.');
                    goProgress();
                } else {
                    if(percent == 0) {
                        showProgressMsg('Reading loaded resources...');
                    } else if(percent == 100) {
                        showProgressMsg(count + ' resources reading complete.');
                    } else {
                        var progStr;
                        progStr = "<table border=0 cellspacing=0 cellpadding=0 width=100% style='table-layout:fixed;'><tr height=15>";
                        progStr += "<td class=prog width=150 style='word-break:break-all;'><b>" + library + "</b></td>";
                        progStr += "<td class=prog width=55 style='text-align:right;'>" + count + "</td>";
                        progStr += "<td class=prog width=40>(" + percent + "%)</td>";
                        progStr += "<td class=prog width=30>READ</td>";
                        progStr += "</tr></table>";
                        showProgressMsg(progStr);
                    }
                    if(percent < 100)
                        setTimeout("pollProgress()", 1000);
                    else
                        hideProgressMsg();
                }
            }
            function showProgressMsg(msg) {
                divProgress.innerHTML = msg;
                divProgress.style.left = 1;
                divProgress.style.top = 1;
                divProgress.style.width = 280;
                divProgress.style.textAlign = 'center';
            }
            function hideProgressMsg() {
                if(divProgress.filters && divProgress.filters.length > 0)
                    window.setTimeout("toggleMultimedia()", 2000);
                window.setTimeout("hideProgressMsgOutside()", 3000);
            }
            function hideProgressMsgOutside() {
                divProgress.innerHTML = '';
                divProgress.style.left = -100;
                divProgress.style.top = -100;
            }
            function findNames(event, idx, fwd) {
                if(event.keyCode != 9) {
                    inputField = document.getElementById("resource");
                    completeDiv = document.getElementById("popup");
                    nameTable = document.getElementById("name_table");
                    nameTableBody = document.getElementById("name_table_body");
                    if(idx == null) {
                        currentName = inputField.value;
                    }
                    if(currentName.trim().length > 0) {
                        xmlHttp = createXMLHttpRequest(xmlHttp);
                        var idxString = (idx==null) ? "" : ("&fwd=" + fwd + "&idx=" + idx);
                        var url = "?action=find&findname=" + currentName + idxString;
                        xmlHttp.open("GET", url, true);
                        xmlHttp.onreadystatechange = findNames_callback;
                        xmlHttp.send(null);
                    } else {
                        clearNames();
                    }
                }
            }
            function findNames_callback() {
                if(xmlHttp.readyState == 4) {
                    if(xmlHttp.status == 200) {
                        var has = xmlHttp.responseXML.getElementsByTagName("has");
                        if(has != null && has[0].firstChild.data == "true") {
                            var idx = xmlHttp.responseXML.getElementsByTagName("index");
                            var fwd = xmlHttp.responseXML.getElementsByTagName("forward");
                            var names = xmlHttp.responseXML.getElementsByTagName("name");
                            if(names != null && names.length > 0)
                                currentIdx = (idx.length<1) ? 0 : Number(idx[0].firstChild.data);
                            setNames(names, fwd);
                        }
                    } else if(xmlHttp.status == 204 || xmlHttp.status == 1223) {
                        clearNames();
                    }
                }
            }
            function createXMLHttpRequest(xmlHttpRequest) {
                if(window.ActiveXObject) {
                    xmlHttpRequest = new ActiveXObject("Microsoft.XMLHTTP");
                } else if(window.XMLHttpRequest) {
                    xmlHttpRequest = new XMLHttpRequest();
                }
                return xmlHttpRequest;
            }
            function no_specialkey(event) {
                if(event.keyCode == 9 || event.keyCode == 13 || (document.theform.findCP.checked && event.keyCode == 32)) {
                    preventKey(event);
                    if(currentRow > -1) {
                        populateOne(event);
                    } else {
                        if(event.keyCode == 13)
                            viewResourceInfo();
                    }
                } else if(event.keyCode == 33 || event.keyCode == 34) {
                    preventKey(event);
                }
            }
            function checkselectkey(event) {
                if(event.keyCode == 32) {
                    preventKey(event);
                } else if(event.keyCode == 38) {
                    if(resultPopupRows != null) {
                        if(currentRow == -1) {
                            currentRow = 0;
                        } else if(currentRow > 0) {
                            currentRow--;
                        } else if(currentRow == 0 && currentIdx > 0) {
                            findNames(event, currentIdx-1, false);
                        }
                        changeSelect();
                    }
                } else if(event.keyCode == 40) {
                    if(resultPopupRows != null) {
                        if(currentRow == -1) {
                            currentRow = 0;
                        } else if(currentRow < resultPopupRows.length-1) {
                            currentRow++;
                        } else if(currentRow == resultPopupRows.length-1) {
                            findNames(event, currentIdx+1, true);
                        }
                        changeSelect();
                    }
                } else if(event.keyCode == 33) {
                    if(resultPopupRows != null) {
                        if(currentRow != 0) {
                            currentRow = 0;
                        } else {
                            if(currentIdx > 0)
                                findNames(event, currentIdx-1, true);
                        }
                        changeSelect();
                    }
                } else if(event.keyCode == 34) {
                    if(resultPopupRows != null) {
                        if(currentRow != resultPopupRows.length-1) {
                            currentRow = resultPopupRows.length-1;
                        } else {
                            findNames(event, currentIdx+1, false);
                        }
                        changeSelect();
                    }
                } else if(event.keyCode == 39) {
                    if(resultPopupRows != null && currentRow > -1) {
                        var item;
                        if(getBrowser() == "FF")
                            item = resultPopupRows[currentRow].cells[0].textContent;
                        else
                            item = resultPopupRows[currentRow].cells[0].outerText;
                        var toIdx = item.indexOf("/", inputField.value.length+1);
                        inputField.value += item.substring(inputField.value.length, (toIdx>-1)?toIdx:item.length);
                        findNames(event, null, null);
                    }
                } else {
                    if(document.theform.findCP.checked)
                        findNames(event,null, null);
                }
            }
            function changeSelect() {
                var cell;
                for(var i = 0; i < resultPopupRows.length; i++) {
                    cell = resultPopupRows[i].cells[0];
                    cell.className = (i==currentRow) ? "mouseOver" : "mouseOut";
                }
            }
            function clearSelect() {
                for(var i = 0; i < resultPopupRows.length; i++) {
                    cell = resultPopupRows[i].cells[0];
                    cell.setAttribute("className", "mouseOut");
                }
            }
            function setNames(the_names, fwd) {
                clearNames();
                var fwd_page = (fwd.length>0) ? fwd[0].firstChild.data : null;
                var size = the_names.length;
                var in_txt = currentName;
                setOffsets();
                var row, cell, txtNode, font;
                for(var i = 0; i < size; i++) {
                    var nextNode = the_names[i].firstChild.data;
                    row = document.createElement("tr");
                    cell = document.createElement("td");
                    cell.className = "mouseOut";
                    cell.onmouseout = function(){clearSelect(); this.className='mouseOut';};
                    cell.onmouseover = function(){clearSelect(); this.className='mouseOver';};
                    cell.onmousedown = function(){populateName(this);};
                    font = document.createElement("font");
                    font.color = "red";
                    txtNode = document.createTextNode(nextNode.substring(0,in_txt.length));
                    font.appendChild(txtNode);
                    cell.appendChild(font);
                    txtNode = document.createTextNode(nextNode.substring(in_txt.length));
                    cell.appendChild(txtNode);
                    row.appendChild(cell);
                    nameTableBody.appendChild(row);
                }
                resultPopupRows = nameTableBody.rows;
                if(fwd_page == null)
                    currentRow = -1;
                else if(fwd_page == 'true')
                    currentRow = 0;
                else if(fwd_page == 'false')
                    currentRow = size-1;
                changeSelect();
            }
            function setOffsets() {
                var end = inputField.offsetWidth;
                var left = calculateOffsetLeft(inputField);
                var top = calculateOffsetTop(inputField) + inputField.offsetHeight;
                completeDiv.style.border = "#404740 1px solid";
                completeDiv.style.left = left + "px";
                completeDiv.style.top = top + "px";
                completeDiv.style.width = end-2 + "px";
                nameTable.style.width = end-2 + "px";
            }
            function calculateOffsetLeft(field) {
                return calculateOffset(field, "offsetLeft");
            }
            function calculateOffsetTop(field) {
                return calculateOffset(field, "offsetTop");
            }
            function calculateOffset(field, attr) {
                var offset = 0;
                while(field) {
                    offset += field[attr];
                    field = field.offsetParent;
                }
                return offset;
            }
            function populateName(cell) {
                if(getBrowser() == "FF")
                    inputField.value = cell.textContent;
                else
                    inputField.value = cell.outerText;
                clearNames();
            }
            function populateOne(event) {
                if(resultPopupRows != null) {
                    if(resultPopupRows.length == 1) {
                        populateName(resultPopupRows[0].cells[0]);
                    } else if(resultPopupRows.length > 1 && currentRow > -1) {
                        populateName(resultPopupRows[currentRow].cells[0]);
                    }
                }
            }
            function clearNames() {
                if(nameTableBody != null) {
                    var ind = nameTableBody.childNodes.length;
                    for(var i = ind-1; i >= 0; i--) {
                         nameTableBody.removeChild(nameTableBody.childNodes[i]);
                    }
                }
                if(completeDiv != null)
                    completeDiv.style.border = "none";
                resultPopupRows = null;
                currentRow = -1;
            }
            function toggleMultimedia() {
                divProgress.filters(0).Apply();
                if(divProgress.style.visibility == "hidden")
                    divProgress.style.visibility = "visible";
                else
                    divProgress.style.visibility = "hidden";
                divProgress.filters(0).Play();
            }
            //-->
        </script>
        <span id="divCursor"></span>
        <span id="divProgress" style="filter:blendTrans(duration=1);"></span>
    </head>
    <body onLoad='<%=(classAutoComplete)?"goProgress(); ":""%>document.theform.resource.focus();'>
        <h2><center>[JVM Property & Class Information View]</center></h2>
        <center><%=version%> -- This is programed by YoungDal,Kwon. TmaxSoft Co. Ltd</center>
        <hr align=center><br>
        <h3>[Class Information]</h3>
        <font style="font-size:12px;">
        <i>- ClassPath</i><br>
        <b>INPUT : <font color=red>Package/ResourceName</font> or <font color=red>Package</font></b><br>
        <b>EXAMPLE : <font color=blue>javax/servlet/http/HttpServlet</font>, <font color=blue>javax/servlet/LocalStrings.properties</font> or <font color=blue>javax/servlet/</font></b><br><br>
        <i>- AbsolutePath</i><br>
        <b>INPUT : <font color=red>AbsolutePath/FileName</font> or <font color=red>AbsolutePath</font></b><br>
        <b>EXAMPLE : <font color=blue>D:/webapps/WEB-INF/web.xml</font> or <font color=blue>/home/webapps/WEB-INF/</font></b><br>
        </font>
        <br><br>
        <form name='theform' method='GET' action=''>
            <table border=0 cellspacing=0 cellpadding=0>
            <tr height=30>
                <td width=110>&nbsp;</td>
                <td colspan=2 valign="top">
                    <input type='radio' id="findCP" name="findcp" value="true" style="margin:-4px 0 -2px 5px;" onFocus="this.blur();" checked> ClassPath</input>
                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                    <input type='radio' id="findAP" name="findcp" value="false" style="margin:-4px 0 -2px 5px;" onFocus="this.blur();" onClick="clearNames();"> AbsolutePath</input>
                </td>
            </tr>
            <tr>
                <td width=110><b>Resource Name : </b></td>
                <td width=550><input type='hidden' name='action' value="view"><input type='text' id='resource' name='resource' class='input' style="width:540px;" onKeyDown="no_specialkey(event);" onKeyUp="checkselectkey(event);" onBlur="clearNames();"></td>
                <td><input type='button' value="Search" onClick="viewResourceInfo();"></td>
            </tr>
            </table>
            <table border=0 cellspacing=0 cellpadding=0>
            <tr>
                <td>
                    <table border=0 cellspacing=0 cellpadding=0 style="table-layout:fixed;">
                    <tr><td width=110>&nbsp;</td></tr>
                    </table>
                </td>
                <td>
                    <div id="popup" style="width:90%;">
                        <table id="name_table" border="0" cellspacing="0" cellpadding="0" style="padding:0,2,0,2;" />
                            <tbody id="name_table_body"></tbody>
                        </table>
                    </div>
                </td>
            </tr>
            </table>
        </form>
        <hr align=center>
        <input type='button' value="System Environment" onClick="show_hide()">
        <div id="property" style="display:none">
            <h3>[ClassLoader Hierarchy]</h3>
            <font color="#404740" style="font-size:9pt;"><%
            ClassLoader loader = Thread.currentThread().getContextClassLoader();
            String clh = "";
            while(loader != null) {
                clh = "<b> - " + linkClass(loader.getClass().getName()) + "</b><br>" + clh;
                loader = loader.getParent();
            }
            out.println(clh);%>
            </font>
            <br><hr align=center>
            <h3>[Loaded Package&Class List]</h3>
            <font color="#404740" style="font-size:9pt;"><%
            for(int i = 0; i < cname.length; i++) {
                url = getResourceURL(cname[i]);
                if(url == null) {
                    out.println("<b> - " + pname[i] + "</b>(" + linkClass(removeExt(cname[i])) + ") : Not Found");
                } else {
                    out.println("<b> - " + pname[i] + "</b>(" + linkClass(removeExt(cname[i])) + ")");
                    out.println(" : [" + linkDownload(checkLocation(url.getFile()), false) + "]\n");
                }
                out.println("<br>");
            }%>
            </font>
            <br><hr align=center>
            <h3>[Security Provider List]</h3>
            <font color="#404740" style="font-size:9pt;"><%
            Provider[] providers = Security.getProviders();
            for(int i = 0; i < providers.length; i++) {
                out.println("<b> - ");
                out.println(providers[i].getName());
                out.println("</b> : ");
                out.println(providers[i].getInfo());
                out.println("<br>");
            }%>
            </font>
            <br><hr align=center>
            <h3>[System Property List]</h3>
            <font color="#404740" style="font-size:9pt;"><%
            Properties prop = System.getProperties();
            Enumeration enum1 = prop.propertyNames();
            while(enum1.hasMoreElements()) {
                name = (String) enum1.nextElement();
                value = (String) prop.get(name);
                out.println("<b> - " + name + "</b> : " + value);
                out.println("<br>");
            }%>
            </font>
        </div>
    </body>
</html><%

    } else if(action.equals("view")) {

        boolean isClass = false;
        boolean isDir = false;
        java.net.URL resUrl = null;
        File absFile = null;
        boolean existFile = true;
        boolean canRead = true;
        boolean isLink = false;
        boolean isErr = false;
        Class cls = null;
        ClassLoader cl = null;
        String noPackageName = "";
        String noExtName = "";
        String findCP = request.getParameter("findcp");
        String resName = request.getParameter("resource");
        if(findCP == null || resName == null || findCP.length() < 1 || resName.length() < 1)
            return;
        boolean inClasspath = findCP.trim().equals("true");
        resName = resName.trim();
        if(inClasspath) {
            resUrl = getResourceURL(resName);
            resUrl = (resUrl == null) ? getResourceURL(replace(resName, ".", "/") + ".class") : resUrl;
            resName = resName.endsWith("/") ? resName.substring(0, resName.length()-1) : resName;
            noPackageName = (resName.lastIndexOf("/")>-1) ? resName.substring(resName.lastIndexOf("/")+1) : resName;
        } else {
            resName = (fsep.equals("/") || (fsep.equals("\\") && resName.indexOf(":") > 0)) ? resName : ("C:/" + resName);
            resName = (fsep.equals("/")) ? replace(resName, "\\", fsep) : replace(resName, "/", fsep);
            resName = replace(resName, fsep+fsep, fsep);
            absFile = new File(resName);
            try {
                existFile = absFile.exists();
                canRead = absFile.canRead();
                resName = (resName.length()>1 && resName.endsWith(fsep)) ? resName.substring(0, resName.length()-1) : resName;
                noPackageName = (resName.lastIndexOf(fsep)>-1) ? resName.substring(resName.lastIndexOf(fsep)+1) : resName;
                isLink = !(absFile.getAbsolutePath().equals(absFile.getCanonicalPath()));
            } catch(SecurityException e) {
                canRead = false;
            }
        }%>
<html>
    <head>
        <title><%=version%> : <%=noPackageName%></title>
        <meta http-equiv="content-type" content="text/html;charset=euc-kr">
        <style type="text/css">
            body{font-size:10pt; font-family:Arial, Apple Gothic, Dotum, Gulim;}
            table{color:#404740; background:#AFAFAF;}
            h2{font-size:15pt}
            h3{font-size:13pt}
            th{font-size:11pt}
            td{font-size:9pt; background:#FFFFFF; padding:1,10,1,10;}
            td.break{word-wrap:break-word; word-break:break-all;}
            th{font-size:9pt; background:#CCCCFF;}
            a{text-decoration: none;}
            a:link,a:visited{color:#0066AA;}
            a:hover{color:#0066AA; background-color:#DDDDDD; border-bottom:1px dotted #0066AA;}
            a.down:link,a.down:visited{color:#FF5555;}
            a.down:hover{color:#FF5555; background-color:#DDDDDD; border-bottom:1px dotted #FF5555;}
            #divCursor{font-size:7pt; font-family:tahoma, Arial, Helvetica, sans-serif; border:1px solid #404740; padding:2px; background-color:#FFFF99; position:absolute; left:-100; top:-50; z-index:1; color:#404740;}
            #divSource{font-size:11px; font-family:tahoma, Arial, Helvetica, sans-serif; padding:10,5,10,5; word-wrap:break-word; word-break:break-all; overflow:auto; background:#f7f7f7; border:#cccccc 1px solid; height:100%;}
        </style>
        <script language="javascript">
            <!--
            function goHome() {
                var u = document.URL;
                document.location.href = u.substring(0, u.indexOf('?'));
            }
            function showMsg_over(msg) {
                divCursor.innerHTML = msg
                divCursor.style.left = event.x+document.body.scrollLeft;
                divCursor.style.top = event.y+document.body.scrollTop-40;
            }
            function showmsg_out() {
                divCursor.innerHTML = '';
                divCursor.style.left = -100;
                divCursor.style.top = -100;
            }
            //-->
        </script>
        <span id="divCursor"></span>
    </head>
    <body><%
        if(inClasspath) {
            if(resUrl == null) {
                if(existResourceName(resName)) {
                    isClass = false;
                    isDir = true;
                } else {
                    out.println(getNotFoundMessage(resName, null));
                    isErr = true;
                }
            } else {
                int fidx = resUrl.getFile().indexOf("!/");
                isClass = resUrl.getFile().endsWith(".class");
                isDir = ((fidx > -1 && resUrl.getFile().substring(fidx+2).indexOf(".") < 0) || (fidx < 0 && new File(checkLocation(resUrl.getFile())).isDirectory())) ? true : false;
                if(!isDir && isClass) {
                    if(resName.startsWith("/"))
                        resName = resName.substring(1);
                    resName = resName.replace('/', '.');
                    noExtName = (resName.endsWith(".class")) ? removeExt(resName) : resName;
                    try {
                        cls = Class.forName(removeExt(resName));
                        cl = cls.getClassLoader();
                    } catch(NoClassDefFoundError e1) {
                        out.println(getNotFoundMessage(resName, e1));
                        e1.printStackTrace();
                        isErr = true;
                    } catch(ClassNotFoundException e2) {
                        out.println(getNotFoundMessage(resName, e2));
                        e2.printStackTrace();
                        isErr = true;
                    }
                }
            }
        } else {
            if(!existFile) {
                out.println(getReadErrorMessage(resName, false));
                isErr = true;
            } else if(!canRead) {
                out.println(getReadErrorMessage(resName, true));
                isErr = true;
            } else {
                isDir = absFile.isDirectory();
            }
        }
        String showName = (isDir) ? noPackageName : ((inClasspath && isClass)?noExtName:noPackageName);
        showName = (showName.trim().equals("")) ? "/" : showName;
        if(inClasspath && isDir && minPackageDepth > 0 && minPackageDepth > getPackageDepth(resName)) {
            out.println("<br><i>The depth of pakage to find have to be over minPackageDepth(" + minPackageDepth + ")</i><br>");
            isErr = true;
        }
        if(!isErr) {%>
        <table border=0 cellspacing=0 width="95%" style="border:none; color:#000000;">
        <tr>
            <td><h3>[<%=(inClasspath && isClass)?"Class Method/Field":"Resource"%> Information]</h3></td>
        </tr>
        </table>
        <menu>
            <li>Summary</li>
            <br><br>
            <table border=0 cellspacing=1 width="90%">
            <thead>
                <tr>
                    <th width=150>Category</th>
                    <th>Value</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td align=center>Name</td>
                    <td align=center><%=(inClasspath && isClass)?getModifierString(cls):""%><b><%=showName%></b></td>
                </tr>
                <tr>
                    <td align=center>Location</td>
                    <td align=center><%=(!inClasspath)?linkDownload(absFile.getAbsolutePath(), isDir):((!isDir)?linkDownload(checkLocation(resUrl.getFile()), isDir):"N/A")%></td>
                </tr><%
                if(inClasspath) {
                    if(!isDir && isClass) {%>
                <tr>
                    <td align=center>ClassLoader</td>
                    <td align=center><%=(cl==null) ? "&nbsp;" : linkClassInfo(cl.toString())%></td>
                </tr>
                <tr>
                    <td align=center>SuperClass</td>
                    <td align=center><%=getModifierString(cls.getSuperclass())%><%=linkClassInfo((cls.getSuperclass()==null) ? "&nbsp;" : cls.getSuperclass().getName())%></td>
                </tr>
                <tr>
                    <td align=center>Interface</td>
                    <td align=center><%=cls.isInterface() ? "Yes" : "No"%></td>
                </tr>
                <tr>
                    <td align=center>Primitive</td>
                    <td align=center><%=cls.isPrimitive() ? "Yes" : "No"%></td>
                </tr><%
                    }
                } else {
                    try {%>
                <tr>
                    <td align=center>Type</td>
                    <td align=center><%=(isDir) ? "Directory" : "File"%></td>
                </tr>
                <tr>
                    <td align=center>Access</td>
                    <td align=center><%=(canRead) ? (absFile.canWrite()?"READ & WRITE":"READ only") : ""%></td>
                </tr>
                <tr>
                    <td align=center>Link</td>
                    <td align=center><%=(isLink) ? linkResource(absFile.getCanonicalPath(), absFile.getCanonicalPath(), false) : "No"%></td>
                </tr>
                <tr>
                    <td align=center>Hidden</td>
                    <td align=center><%=absFile.isHidden() ? "Yes" : "No"%></td>
                </tr>
                <tr>
                    <td align=center>LastModified</td>
                    <td align=center><%=(new SimpleDateFormat("yyyy/MM/dd HH:mm:ss")).format(new Date(absFile.lastModified()))%></td>
                </tr><%
                    } catch(Exception e) {}
                }%>
            </tbody>
            </table>
            <br><br><%
            String content = null;
            Class[] ifs = null;
            Constructor[] dcons = null;
            Field[] dfls = null;
            Method[] dmtds = null;
            Class[] dcls = null;
            String errorStr = null;
            if(inClasspath) {
                if((!isDir && !isClass) || (isDir)) {
                    if(isDir && (resUrl == null || checkLocation(resUrl.getFile()).indexOf(" >> ") > -1))
                        content = readLibraryDir(resName);
                    else
                        content = readContent(resUrl, ((isDir)?resName:null));
                } else if(isClass) {
                    if(cl == null)
                        cl = Thread.currentThread().getContextClassLoader();
                    if(cl != null) {
                        ifs = cls.getInterfaces();
                        dcons = cls.getDeclaredConstructors();
                        dfls = cls.getDeclaredFields();
                        dmtds = cls.getDeclaredMethods();
                        dcls = cls.getDeclaredClasses();
                    }
                }
            } else {
                try {
                    if(isDir)
                        content = readDirectory(resName);
                    else
                        content = readContent(resName);
                } catch(Exception e) {
                    errorStr = e.getMessage();
                }
            }
            if(content != null) {%>
            <li><%=(isDir)?"List":"Contents"%></li><br><br>
            <table border=0 cellspacing=1 width="90%">
            <tr>
                <td style="padding:2;">
                    <div id="divSource">
                        <%=content%>
                    </div>
                </td>
            </tr>
            </table><%
            } else {
                if(!inClasspath) {
                    String msg = "<br><i>Can't read the resource '<font color=#228B22>" + absFile.getAbsolutePath() + "</font>'.</i><br>";
                    if(errorStr != null)
                        msg += "<br>Cause : " + errorStr + "<br>";
                    out.println(msg + "<br>");
                }
            }
            if(inClasspath && isClass) {%>
            <li>Details</li><br><br>
            <table border=0 cellspacing=1 width="90%">
            <thead>
                <tr>
                    <th width=95>Category</th>
                    <th>Type</th>
                    <th width=150>Modifier</th>
                    <th>Detail</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td align=center <%=(ifs.length>1)?("rowspan="+ifs.length):""%>>Implemented</td>
                    <td align=center <%=(ifs.length>1)?("rowspan="+ifs.length):""%>>N/A</td><%
                    for(int i=0; i<ifs.length; i++) {
                        if(i > 0)
                            out.println("</tr><tr>");
                        out.println("<td width=150 align=center>" + getModifierString(ifs[i]) + "</td>");
                        out.println("<td class='break' align=center>" + linkClassInfo(ifs[i].getName()) + "</td>");
                    }
                    if(ifs.length == 0)
                        out.println("<td>&nbsp;</td><td>&nbsp;</td>");%>
                </tr>
                <tr>
                    <td align=center <%=(dcons.length>1)?("rowspan="+dcons.length):""%>>Constructor</td>
                    <td align=center <%=(dcons.length>1)?("rowspan="+dcons.length):""%>>N/A</td><%
                    for(int i=0; i<dcons.length; i++) {
                        String conStr = dcons[i].getName();
                        if(i > 0)
                            out.println("</tr><tr>");
                        out.println("<td width=150 align=center>" + getModifierString(dcons[i].getModifiers()) + "</td>");
                        out.println("<td class='break' align=center>" + conStr.substring(conStr.lastIndexOf('.')+1) + "(");
                        Class[] params = dcons[i].getParameterTypes();
                        for(int j=0; j<params.length; j++) {
                            if(j!=0) out.println(", ");
                            out.println(linkClassInfo(params[j].getName()));
                        }
                        out.println(")</td>");
                    }
                    if(dcons.length == 0)
                        out.println("<td>&nbsp;</td><td>&nbsp;</td>");%>
                </tr>
                <tr>
                    <td align=center <%=(dfls.length>1)?("rowspan="+dfls.length):""%>>Field</td><%
                    for(int i=0; i<dfls.length; i++) {
                        Class type = dfls[i].getType();
                        if(i > 0)
                            out.println("</tr><tr>");
                        out.println("<td class='break' align=center>" + linkClassInfo(type.getName()) + "</td>");
                        out.println("<td width=150 align=center>" + getModifierString(dfls[i].getModifiers()) + "</td>");
                        out.println("<td class='break' align=center>" + dfls[i].getName() + "</td>");
                    }
                    if(dfls.length == 0) {
                        out.println("<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>");
                    }%>
                </tr>
                <tr>
                    <td align=center <%=(dmtds.length>1)?("rowspan="+dmtds.length):""%>>Method</td><%
                    for(int i=0; i<dmtds.length; i++) {
                        Class type = dmtds[i].getReturnType();
                        if(i > 0)
                            out.println("</tr><tr>");
                        out.println("<td class='break' align=center>" + linkClassInfo(type.getName()) + "</td>");
                        out.println("<td width=150 align=center>" + getModifierString(dmtds[i].getModifiers()) + "</td>");
                        out.println("<td class='break' align=center>" + dmtds[i].getName() + "(");
                        Class[] params = dmtds[i].getParameterTypes();
                        for(int j=0; j<params.length; j++) {
                            if(j!=0) out.println(", ");
                            out.println(linkClassInfo(params[j].getName()));
                        }
                        out.println(")</tr>");
                    }
                    if(dmtds.length == 0) {
                        out.println("<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>");
                    }%>
                </tr>
                <tr>
                    <td align=center <%=(dcls.length>1)?("rowspan="+dcls.length):""%>>InnerClass</td>
                    <td align=center <%=(dcls.length>1)?("rowspan="+dcls.length):""%>>N/A</td><%
                    for(int i=0; i<dcls.length; i++) {
                        if(i > 0)
                            out.println("</tr><tr>");
                        out.println("<td width=150 align=center>" + getModifierString(dcls[i]) + "</td>");
                        out.println("<td class='break' align=center>" + linkClassInfo(dcls[i].getName()) + "</td>");
                    }
                    if(dcls.length == 0)
                        out.println("<td>&nbsp;</td><td>&nbsp;</td>");%>
                </tr>
            </tbody>
            </table><%
            }%>
        </menu><%
        }%>
        <br><br><br>
        <center>
            <table border=0 cellspacing=0 cellpadding=0 align="center">
            <tr>
                <td align="center" width=100><input type="button" value="HOME" onClick="goHome();"></td>
                <td align="center" width=100><input type="button" value="BACK" onClick="history.back();"></td>
            </tr>
            </table>
        </center>
    </body>
</html><%

    } else if(action.equals("find")) {

        String fwd = request.getParameter("fwd");
        String idx = request.getParameter("idx");
        StringBuffer ret = new StringBuffer("");
        try {
            request.setCharacterEncoding("UTF-8");
            String prefix = request.getParameter("findname");
            prefix = replace(prefix, ".", "/");
            idx = (idx==null || idx.trim().length()<1) ? "0" : idx;
            List matching = findResourceNames(prefix, idx);
            if(matching != null) {
                if(matching.size() > 0) {
                    response.setContentType("text/xml");
                    response.setHeader("Cache-Control", "no-cache");
                    ret.append("<response>\n");
                    ret.append("<has>true</has>\n");
                    if(fwd != null && fwd.trim().length() > 0 && idx != null && idx.trim().length() > 0) {
                        ret.append("<forward>" + fwd + "</forward>\n");
                        ret.append("<index>" + idx + "</index>\n");
                    }
                    Iterator iter = matching.iterator();
                    while(iter.hasNext()) {
                        name = (String)iter.next();
                        ret.append("<name>" + name + "</name>\n");
                    }
                    ret.append("</response>");
                    out.println(ret.toString());
                    matching = null;
                } else {
                    if(Integer.parseInt(idx) > 0) {
                        response.setContentType("text/xml");
                        response.setHeader("Cache-Control", "no-cache");
                        ret.append("<response>\n");
                        ret.append("<has>false</has>\n");
                        ret.append("</response>");
                        out.println(ret.toString());
                    } else {
                        response.setStatus(HttpServletResponse.SC_NO_CONTENT);
                    }
                }
            } else {
                response.setStatus(HttpServletResponse.SC_NO_CONTENT);
            }
        } catch(Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }

    } else if(action.equals("load")) {

        isLoading = true;
        ClassLoader cloader = Thread.currentThread().getContextClassLoader();
        getLoadedResources(application, cloader.toString());

    } else if(action.equals("progress")) {

        StringBuffer ret = new StringBuffer("");
        try {
            request.setCharacterEncoding("UTF-8");
            response.setContentType("text/xml");
            response.setHeader("Cache-Control", "no-cache");
            ret.append("<response>\n");
            ret.append("<loading>" + isLoading + "</loading>\n");
            ret.append("<percent>" + percentComplete + "</percent>\n");
            ret.append("<count>" + loadedResourceCount + "</count>\n");
            ret.append("<library>" + libraryLoading + "</library>\n");
            ret.append("</response>");
            out.println(ret.toString());
        } catch(Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }

    } else if(action.equals("down")) {

        String type = request.getParameter("type");
        String target = request.getParameter("target");
        if(type != null && type.length() > 0 && target != null && target.length() > 0) {
            try {
                if(type.trim().equals("file"))
                    downloadFile(target, response);
                else if(type.trim().equals("resource"))
                    downloadResource(target, response);
            } catch(Exception e) {
                e.printStackTrace();
                out.println("<script language='javascript'>alert('Can\\'t download the file\\nCause : " + e.getMessage() + "')</script>");
            }
        }

    }
%>

