Dynamsoft.DWT.AutoLoad = false;
Dynamsoft.DWT.RegisterEvent('OnWebTwainReady', Dynamsoft_OnReady); // Register OnWebTwainReady event. This event fires as soon as Dynamic Web TWAIN is initialized and ready to be used

var DWObject, blankField = "",
    extrFieldsCount = 0,
    upload_returnSth = true,
    strHTTPServer = location.hostname,
    strActionPage, strFullActionPagePath, ObjString,
    CurrentPathName = unescape(location.pathname),
    CurrentPath = CurrentPathName.substring(0, CurrentPathName.lastIndexOf("/") + 1);

var scriptLanguages = [
    { desc: "PHP", val: "php" },
    { desc: "PHP-MySQL", val: "phpMySQL" },
    { desc: "CSharp", val: "csharp" },
    { desc: "CSharp-MSSQL", val: "csMSSQL" },
    { desc: "VB.NET", val: "vbnet" },
    { desc: "VBNET-MSSQL", val: "vbnetMSSQL" },
    { desc: "JSP", val: "jsp" },
    { desc: "JSP-Oracle", val: "jspOracle" },
    { desc: "ASP", val: "asp" },
    { desc: "ASP-MSSQL", val: "aspMSSQL" },
    { desc: "ColdFusion", val: "cfm" },
    { desc: "CS-Azure", val: "csAzure" }
];

window.onload = function() {
    if (Dynamsoft) {
        Dynamsoft.DWT.Load();
    }
};

function languageSelected() {
    if (document.getElementById("ddlLanguages").selectedIndex > 7)
        upload_returnSth = false;
    else
        upload_returnSth = true;
    if ([0, 2, 4, 6].indexOf(document.getElementById("ddlLanguages").selectedIndex) == -1) {
        document.getElementById("extra-fields-div-id").style.display = 'none';
        document.getElementById('div-extra-fields').style.display = 'none';
    } else {
        document.getElementById("extra-fields-div-id").style.display = '';
        if (document.getElementById('div-extra-fields').children.length > 1 ||
            document.getElementById('div-extra-fields').children[0].children[0].value != '') {
            document.getElementById('div-extra-fields').style.display = '';
        }
    }
}

function addAField() {
    extrFieldsCount++;
    if (extrFieldsCount == 3) {
        document.getElementById('div-extra-fields').style.overflowY = 'scroll';
    }
    if (document.getElementById('div-extra-fields').style.display == "none")
        document.getElementById('div-extra-fields').style.display = '';
    else {
        document.getElementById('div-extra-fields').appendChild(blankField);
        blankField = document.getElementsByClassName('div-fields-item')[extrFieldsCount - 1].cloneNode(true);
    }
}

function Dynamsoft_OnReady() {
    blankField = document.getElementsByClassName('div-fields-item')[0].cloneNode(true);
    DWObject = Dynamsoft.DWT.GetWebTwain('dwtcontrolContainer');
    if (DWObject) {
        DWObject.Viewer.width = 505;
        DWObject.Viewer.height = 600;
        for (var i = 0; i < scriptLanguages.length; i++)
            document.getElementById("ddlLanguages").options.add(new Option(scriptLanguages[i].desc, i));
        document.getElementById("ddlLanguages").options.selectedIndex = 2;

        DWObject.RegisterEvent('OnGetFilePath', ds_load_file_to_upload_directly);

        if (DWObject.Addon.PDF.IsModuleInstalled()) {
            /** PDFR already installed */
        }
    }
}

function AcquireImage() {
    if (DWObject) {
        DWObject.SelectSource(function() {
            var OnAcquireImageSuccess, OnAcquireImageFailure;
            OnAcquireImageSuccess = OnAcquireImageFailure = function() {
                DWObject.CloseSource();
            };
            DWObject.OpenSource();
            DWObject.IfDisableSourceAfterAcquire = true;
            DWObject.AcquireImage(OnAcquireImageSuccess, OnAcquireImageFailure);
        }, function() {
            console.log('SelectSource failed!');
        });
    }
}

var bUpload = false;

function LoadImages() {
    if (DWObject) {
        if (DWObject.Addon && DWObject.Addon.PDF) {
            DWObject.Addon.PDF.SetResolution(300);
            DWObject.Addon.PDF.SetConvertMode(Dynamsoft.DWT.EnumDWT_ConvertMode.CM_RENDERALL);
        }
        bUpload = false;
        DWObject.IfShowFileDialog = true;
        DWObject.LoadImageEx('', 5,
            function() {},
            function(errorCode, errorString) {
                alert('Load Image:' + errorString);
            }
        );
    }
}

function OnHttpUploadSuccess() {
    console.log('successful');
}

function OnHttpServerReturnedSomething(errorCode, errorString, sHttpResponse) {
    if (errorCode != 0 && errorCode != -2003)
        alert(errorString);
    else {
        var textFromServer = sHttpResponse;
        _printUploadedFiles(textFromServer);
    }
}

function _printUploadedFiles(info) {
    //console.log(info);
    if (info.indexOf('DWTUploadFileName') != -1) {
        var url, _strPort;
        DWObject.IfSSL = Dynamsoft.Lib.detect.ssl;
        _strPort = location.port == "" ? 80 : location.port;
        url = 'http://' + location.hostname + ':' + location.port;
        if (Dynamsoft.Lib.detect.ssl == true) {
            _strPort = location.port == "" ? 443 : location.port;
            url = 'https://' + location.hostname + ':' + location.port;
        }
        var savedIntoToDB = false,
            imgIndexInDB = "-1";
        if (info.indexOf("DWTUploadFileIndex:") != -1) {
            savedIntoToDB = true;
            imgIndexInDB = info.substring(info.indexOf('DWTUploadFileIndex') + 19, info.indexOf('DWTUploadFileName'));
            //console.log(imgIndexInDB);
        }
        var fileName = info.substring(info.indexOf('DWTUploadFileName') + 18, info.indexOf('UploadedFileSize'));
        var fileSize = info.substr(info.indexOf('UploadedFileSize') + 17);
        if (savedIntoToDB) {
            if (info.indexOf('CSHARP') != -1) {
                url += CurrentPath + 'action/csharp-db.aspx?imgID=' + imgIndexInDB;
            } else if (info.indexOf('VBNET') != -1) {
                url += CurrentPath + 'action/vbnet-db.aspx?imgID=' + imgIndexInDB;
            } else if (info.indexOf('PHP') != -1) {
                url += CurrentPath + 'action/php-mysql.php?imgID=' + imgIndexInDB;
            } else if (info.indexOf('JSP') != -1) {
                url += CurrentPath + 'action/jsp-oracle.jsp?imgID=' + imgIndexInDB;
            }
        } else {
            url += CurrentPath + 'action/Dynamsoft_Upload/' + encodeURI(fileName);
        }
        var newTR = document.createElement('tr');
        _str = "<td class='tc'><a class='bluelink'" + ' href="' + url + '" target="_blank">' + fileName + "</a></td>" + "<td class='tc'>" + fileSize + '</td>';
        if (info.indexOf("FieldsTrue:") != -1)
            _str += "<td class='tc'><a class='bluelink'" + '" href="' + url.substring(0, url.length - 4) + '_1.txt' + '" target="_blank">Fields</td>';
        else {
            _str += "<td class='tc'>No Fields</td>";
        }
        newTR.innerHTML = _str;
        document.getElementById('div-uploadedFile').appendChild(newTR);
    }
}

function upload_preparation(_name) {
    DWObject.IfShowCancelDialogWhenImageTransfer = !document.getElementById('quietScan').checked;
    strActionPage = CurrentPath + 'action/';
    switch (document.getElementById("ddlLanguages").options.selectedIndex) {
        case 0:
            strActionPage += "php.php";
            break;
        case 2:
            strActionPage += "csharp.aspx";
            break;
        case 6:
            strActionPage += "jsp.jsp";
            break;
        case 4:
            strActionPage += "vbnet.aspx";
            break;
        case 8:
            strActionPage += "asp.asp";
            break;
        case 10:
            strActionPage += "cfm.cfm";
            break;
        case 1:
            strActionPage += "php-mysql.php?imgID=new";
            break;
        case 7:
            strActionPage += "jsp-oracle.jsp?imgID=new";
            break;
        case 3:
            strActionPage += "csharp-db.aspx?imgID=new";
            break;
        case 5:
            strActionPage += "vbnet-db.aspx?imgID=new";
            break;
        case 9:
            strActionPage += "asp-db.asp";
            break;
        case 11:
            preparetoUploadtoAzure(_name);
            break;
        default:
            break;
    }
    DWObject.IfSSL = Dynamsoft.Lib.detect.ssl;
    var _strPort = location.port == "" ? 80 : location.port;
    if (Dynamsoft.Lib.detect.ssl == true) {
        _strPort = location.port == "" ? 443 : location.port;
        strFullActionPagePath = "https://" + strHTTPServer + ":" + _strPort + strActionPage;
    } else {
        strFullActionPagePath = "http://" + strHTTPServer + ":" + _strPort + strActionPage;
    }

    DWObject.HTTPPort = _strPort;
    if ([0, 2, 4, 6].indexOf(document.getElementById("ddlLanguages").selectedIndex) != -1) {
        /* Add Fields to the Post */
        var fields = document.getElementsByClassName('div-fields-item');

        DWObject.ClearAllHTTPFormField();
        for (var n = 0; n < fields.length; n++) {
            var o = fields[n];
            if (o.children[0].value != '')
                DWObject.SetHTTPFormField(o.children[0].value, o.children[1].value);
        }
    }
}

function UploadImage_inner() {
    if (DWObject.HowManyImagesInBuffer == 0)
        return;

    var i, aryIndices = [],
        Digital = new Date(),
        uploadfilename = Digital.getMilliseconds();
    upload_preparation(uploadfilename);
    // Upload the image(s) to the server asynchronously
    if (document.getElementById("ddlLanguages").options.selectedIndex == 11 /*Azure*/ ) return;

    if (document.getElementsByName('ImageType')[0].checked) {
        var count = DWObject.HowManyImagesInBuffer;
        aryIndices = [];
        for (i = 0; i < count; i++) aryIndices.push(i);

        var uploadJPGsOneByOne = function(errorCode, errorString, sHttpResponse) {
            if (errorCode != 0 && errorCode != -2003) {
                alert(errorString);
                return;
            }

            if (upload_returnSth)
                _printUploadedFiles(sHttpResponse);
            if (aryIndices.length > 0) {
                if (upload_returnSth)
                    DWObject.HTTPUpload(strFullActionPagePath, aryIndices.splice(0, 1), Dynamsoft.DWT.EnumDWT_ImageType.IT_JPG, Dynamsoft.DWT.EnumDWT_UploadDataFormat.Binary, uploadfilename + "-" + (count - aryIndices.length) + ".jpg", OnHttpUploadSuccess, uploadJPGsOneByOne);
                else
                    DWObject.HTTPUpload(strFullActionPagePath, aryIndices.splice(0, 1), Dynamsoft.DWT.EnumDWT_ImageType.IT_JPG, Dynamsoft.DWT.EnumDWT_UploadDataFormat.Binary, uploadfilename + "-" + (count - aryIndices.length) + ".jpg", uploadJPGsOneByOne, OnHttpServerReturnedSomething);
            }
        };
        if (upload_returnSth)
            DWObject.HTTPUpload(strFullActionPagePath, aryIndices.splice(0, 1), Dynamsoft.DWT.EnumDWT_ImageType.IT_JPG, Dynamsoft.DWT.EnumDWT_UploadDataFormat.Binary, uploadfilename + "-" + (count - aryIndices.length) + ".jpg", OnHttpUploadSuccess, uploadJPGsOneByOne);
        else
            DWObject.HTTPUpload(strFullActionPagePath, aryIndices.splice(0, 1), Dynamsoft.DWT.EnumDWT_ImageType.IT_JPG, Dynamsoft.DWT.EnumDWT_UploadDataFormat.Binary, uploadfilename + "-" + (count - aryIndices.length) + ".jpg", uploadJPGsOneByOne, OnHttpServerReturnedSomething);
    } else if (document.getElementsByName('ImageType')[1].checked) {
        aryIndices = [];
        for (i = 0; i < DWObject.HowManyImagesInBuffer; i++) aryIndices.push(i);
        DWObject.HTTPUpload(strFullActionPagePath, aryIndices, Dynamsoft.DWT.EnumDWT_ImageType.IT_TIF, Dynamsoft.DWT.EnumDWT_UploadDataFormat.Binary, uploadfilename + ".tif", OnHttpUploadSuccess, OnHttpServerReturnedSomething);
    } else if (document.getElementsByName('ImageType')[2].checked) {
        aryIndices = [];
        for (i = 0; i < DWObject.HowManyImagesInBuffer; i++) aryIndices.push(i);
        DWObject.HTTPUpload(strFullActionPagePath, aryIndices, Dynamsoft.DWT.EnumDWT_ImageType.IT_PDF, Dynamsoft.DWT.EnumDWT_UploadDataFormat.Binary, uploadfilename + ".pdf", OnHttpUploadSuccess, OnHttpServerReturnedSomething);
    }
}

var aryFilePaths = [];

function ds_load_file_to_upload_directly(bSave, filesCount, index, path, filename) {
    nCount = filesCount;
    var filePath = path + "\\" + filename;
    if (Dynamsoft.Lib.env.bLinux || Dynamsoft.Lib.env.bMac)
        filePath = path + "/" + filename;
    aryFilePaths.push(filePath);
    if (bUpload == true) {
        if (aryFilePaths.length == nCount) {
            upload_preparation();
            var i = 0;
            var uploadFileOneByOne = function() {
                DWObject.HTTPUploadThroughPostDirectly(strHTTPServer, filePath, strActionPage, filename,
                    function() {
                        console.log('Upload Image:' + aryFilePaths[i] + ' -- successful');
                        i++;
                        if (i != nCount)
                            uploadFileOneByOne();
                        else
                            bUpload = false;
                    },
                    OnHttpServerReturnedSomething
                );
            };
            uploadFileOneByOne();
        }
    }
};

function UploadImage() {
    if (DWObject) {
        var nCount = 0,
            nCountUpLoaded = 0;
        aryFilePaths = [];
        if (document.getElementById('uploadDirectly').checked) {
            bUpload = true;
            DWObject.IfShowCancelDialogWhenImageTransfer = false;
            if (Dynamsoft.Lib.env.bMac)
                DWObject.ShowFileDialog(false, "TIF,TIFF,JPG,JPEF,PNG,PDF", 0, "", "", true, false, 0);
            else
                DWObject.ShowFileDialog(false, "Any File | *.*", 0, "", "", true, true, 0);
        } else {
            UploadImage_inner();
        }
    }
}


/*******************/
/* Upload to Azure */

var Base64Binary = {
    _keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
    decode: function(input, arrayBuffer) {
        //get last chars to see if are valid
        var lkey1 = this._keyStr.indexOf(input.charAt(input.length - 1));
        var lkey2 = this._keyStr.indexOf(input.charAt(input.length - 2));
        var bytes = (input.length / 4) * 3;
        if (lkey1 == 64) bytes--; //padding chars, so skip
        if (lkey2 == 64) bytes--; //padding chars, so skip		
        var uarray;
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;
        var j = 0;
        if (arrayBuffer)
            uarray = new Uint8Array(arrayBuffer);
        else
            uarray = new Uint8Array(bytes);
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
        for (i = 0; i < bytes; i += 3) {
            //get the 3 octects in 4 ascii chars
            enc1 = this._keyStr.indexOf(input.charAt(j++));
            enc2 = this._keyStr.indexOf(input.charAt(j++));
            enc3 = this._keyStr.indexOf(input.charAt(j++));
            enc4 = this._keyStr.indexOf(input.charAt(j++));
            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;
            uarray[i] = chr1;
            if (enc3 != 64) uarray[i + 1] = chr2;
            if (enc4 != 64) uarray[i + 2] = chr3;
        }
        return uarray;
    }
};

function uploadImageInner_azure(blobSasUrl, fileDataAsArrayBuffer) {
    var ajaxRequest = new XMLHttpRequest();
    try {
        ajaxRequest.open('PUT', blobSasUrl, true);
        ajaxRequest.setRequestHeader('x-ms-blob-type', 'BlockBlob');
        ajaxRequest.send(fileDataAsArrayBuffer);
        ajaxRequest.onreadystatechange = function() {
            if (ajaxRequest.readyState == 4) {
                console.log('Upload image to azure server successfully.');
            }
        };
    } catch (e) {
        console.log("can't upload the image to server.\n" + e.toString());
    }
}

function preparetoUploadtoAzure(__name) {
    var uploadfilename = '';
    //For JPEG, upload the current image
    if (document.getElementsByName('ImageType')[0].checked) {
        DWObject.GetSelectedImagesSize(Dynamsoft.DWT.EnumDWT_ImageType.IT_JPG);
        uploadfilename = __name + '.jpg';
    } else { //For TIFF, PDF, upload all images
        var nCount = DWObject.HowManyImagesInBuffer;
        var arySelectIndex = [];
        for (i = 0; i < nCount; i++) {
            arySelectIndex.push(i);
        }
        DWObject.SelectImages(arySelectIndex);
        if (document.getElementsByName('ImageType')[1].checked) {
            DWObject.GetSelectedImagesSize(Dynamsoft.DWT.EnumDWT_ImageType.IT_TIF);
            uploadfilename = __name + '.tif';
        } else {
            DWObject.GetSelectedImagesSize(Dynamsoft.DWT.EnumDWT_ImageType.IT_PDF);
            uploadfilename = __name + '.pdf';
        }
    }

    var strImg, aryImg, _uint8_STR, _bin_ARR, _blobImg;
    strImg = DWObject.SaveSelectedImagesToBase64Binary();
    // convert base64 to Uint8Array
    var bytes = (strImg.length / 4) * 3;
    var _temp = new ArrayBuffer(bytes);
    _uint8_STR = Base64Binary.decode(strImg, _temp);

    // convert Uint8Array to blob
    _blobImg = new Blob([_uint8_STR]);
    // upload to Azure server
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4) {
            uploadImageInner_azure(xhr.responseText, _blobImg);
        }
    };
    var actionPageFullPath = CurrentPath + 'action/' + 'azure.aspx?imageName=' + uploadfilename;
    xhr.open('GET', actionPageFullPath, true);
    xhr.send();
}
/*******************/