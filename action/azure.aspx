<%@ Page Language="C#" %>

<%
    DateTime utc = DateTime.Now.ToUniversalTime();

    // (1) Prepare your data
    String accountName = "dynamsoft";
    String accountKey = "";
    String baseUrl = "http://dynamsoft.blob.core.windows.net/dwt/";
    String resourceName = Request["imageName"];
    String path = "/dwt";
    DateTime utc_start = utc.AddSeconds(-10);           // 10 seconds before
    String start = utc_start.GetDateTimeFormats('s')[0].ToString() + ".0000000Z";
    DateTime utc_expires = utc.AddSeconds(1200);        // 20 miniteus later
    String expires = utc_expires.GetDateTimeFormats('s')[0].ToString() + ".0000000Z";


    // (2) generate signature
    String strToSign1 = "w";
    String strToSign2 = start;
    String strToSign3 = expires;
    String strToSign4 = "/" + accountName + path;
    String strToSign5 = "";
    String strSign = String.Format("{0}\n{1}\n{2}\n{3}\n{4}", strToSign1, strToSign2, strToSign3, strToSign4, strToSign5);

    // decoding
    byte[] tobedecodedbytes = System.Convert.FromBase64String(accountKey);
    System.Security.Cryptography.HMACSHA256 hmac = new System.Security.Cryptography.HMACSHA256(tobedecodedbytes);
    hmac.Initialize();
    byte[] buffer = Encoding.UTF8.GetBytes(strSign);
    byte[] arrMAC = hmac.ComputeHash(buffer);
    String strSig = System.Convert.ToBase64String(arrMAC);

    // (3) generate SAS the query 
    start = Server.UrlEncode(start);
    expires = Server.UrlEncode(expires);
    strSig = Server.UrlEncode(strSig);
    String strParams = String.Format("sp=w&st={0}&se={1}&sr=c&sig={2}", start, expires, strSig);
    String url = baseUrl + resourceName + "?" + strParams;
    Response.Write(url);
%>