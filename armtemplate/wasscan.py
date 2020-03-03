import sys, requests, os, time, json, base64

USERNAME = str(os.environ['QUALYS_USERNAME']) #Create as Pipeline Variable
PASSWORD = str(os.environ['QUALYS_PASSWORD']) #Create as Pipeline Variable
URL = str(os.environ['QUALYS_API_SERVER'])  #Create as Pipeline Variable
ProfileId = str(os.environ['QUALYS_WAS_PROFILEID']) #Create as Pipeline Variable
webAppUserName = str(os.environ['WEBAPP_USERNAME']) #Create as Pipeline Variable
webAppPassWord = str(os.environ['WEBAPP_PASSWORD']) #Create as Pipeline Variable
webAppURL = str(os.environ['WEBAPPURL_APPSERVICEAPPLICATIONURL']) #pass it as a variable from QA Slot

usrPass = (str(USERNAME)+':'+str(PASSWORD)).encode('ascii')
b64Val = (base64.b64encode(usrPass)).decode("utf-8")
headers = {
    'Accept': 'application/json',
    'content-type': 'application/xml',
    'X-Requested-With' : 'python requests',
    'Authorization': "Basic %s" % b64Val
    }

def createAuthRecord(headers,URL,webAppUserName,webAppPassWord,webAppURL,ProfileId):
    authRecordURL = URL + "/qps/rest/3.0/create/was/webappauthrecord/"
    authRecordName="WebApp" + webAppUserName + str(time.strftime("%Y%m%d-%H%M%S"))
    authRecordbody="""
    <ServiceRequest>
     <data>
     <WebAppAuthRecord>
         <name><![CDATA[{0}]]></name>
         <formRecord>
             <type>STANDARD</type>
             <sslOnly>true</sslOnly>
             <fields>
                 <set>
                     <WebAppAuthFormRecordField>
                         <name>username</name>
                         <value>{1}</value>
                     </WebAppAuthFormRecordField>
                     <WebAppAuthFormRecordField>
                         <name>password</name>
                         <value>{2}</value>
                     </WebAppAuthFormRecordField>
                 </set>
             </fields>
         </formRecord>
     </WebAppAuthRecord>
     </data>
    </ServiceRequest>
    """.format(authRecordName,webAppUserName,webAppPassWord)
    try:
        r = requests.post(authRecordURL, data=authRecordbody, headers=headers)
        runResult = json.loads(str(r.text))
        if str(runResult['ServiceResponse']['responseCode']) == "SUCCESS":
            authRecordId = runResult['ServiceResponse']['data'][0]['WebAppAuthRecord']['id']
            webAppId = createWebApp(authRecordId,headers,URL,webAppURL,ProfileId)
            print (webAppId)
            return webAppId
        else:
            print (runResult['ServiceResponse']['responseCode'], runResult['ServiceResponse']['responseErrorDetails']['errorMessage'])
        
    except IOError as e:
        print("Error {0}: {1}".format(e.errno, e.strerror))

def createWebApp(authRecordId,headers,URL,webAppURL,ProfileId):
    webApplURL = URL + "/qps/rest/3.0/create/was/webapp/"
    webAppName="WebApp" + webAppURL + str(time.strftime("%Y%m%d-%H%M%S"))
    webAppbody="""
        <ServiceRequest>
         <data>
         <WebApp>
             <name><![CDATA[{0}]]></name>
              <url><![CDATA[{1}]]></url>
             <authRecords>
                 <set>
                    <WebAppAuthRecord>
                        <id>{2}</id>
                    </WebAppAuthRecord>
                 </set>
             </authRecords>
             <defaultProfile>
                <id>{3}</id>
             </defaultProfile>
             <defaultScanner>
                <type>EXTERNAL</type>
             </defaultScanner>
         </WebApp>
         </data>
        </ServiceRequest>
    """.format(webAppName,webAppURL,authRecordId,ProfileId)
    try:
        r = requests.post(webApplURL, data=webAppbody, headers=headers)
        runResult = json.loads(str(r.text))
        if str(runResult['ServiceResponse']['responseCode']) == "SUCCESS":
            webAppId = runResult['ServiceResponse']['data'][0]['WebApp']['id']
            return webAppId
        else:
            print (runResult['ServiceResponse']['responseCode'], runResult['ServiceResponse']['responseErrorDetails']['errorMessage'])
    except IOError as e:
        print("Error {0}: {1}".format( e.errno, e.strerror))
        
def scanWebApp(headers,URL,webAppId):
    scanWebAppURL = URL + "/qps/rest/3.0/launch/was/wasscan/"
    scanWebAppName="Azure-DevOps-CI-Scan-" + str(webAppId) + str(time.strftime("%Y%m%d-%H%M%S"))
    scanWebAppbody="""
        <ServiceRequest>
           <data>
              <WasScan>
                 <name>{0}</name>
                 <type>VULNERABILITY</type>
                 <target>
                    <webApp>
                       <id>{1}</id>
                    </webApp>
                    <webAppAuthRecord>
                       <isDefault>true</isDefault>
                    </webAppAuthRecord>
                    <scannerAppliance>
                       <type>EXTERNAL</type>
                    </scannerAppliance>
                 </target>
              </WasScan>
           </data>
        </ServiceRequest>
    """.format(scanWebAppName,webAppId)
    try:
        r = requests.post(scanWebAppURL, data=scanWebAppbody, headers=headers)
        runResult = json.loads(str(r.text))
        if str(runResult['ServiceResponse']['responseCode']) == "SUCCESS":
            scanWebAppId = runResult['ServiceResponse']['data'][0]['WasScan']['id']
            print ("WebAPP:{0}, ScanID:{1}".format(webAppId,scanWebAppId))
            return scanWebAppId
        else:
            print (runResult['ServiceResponse']['responseCode'], runResult['ServiceResponse']['responseErrorDetails']['errorMessage'])
    except IOError as e:
        print("Error {0}: {1}".format( e.errno, e.strerror))

def checkVulnStatusWebApp(headers,URL,scanWebAppId):
    print('Scanning Vulnerability Scan is still runiing or not')
    checkVulnStatusWebAppURL = URL + "/qps/rest/3.0/status/was/wasscan/" + str(scanWebAppId)
    scanRunning = True
    while scanRunning:
        r = requests.get(checkVulnStatusWebAppURL, headers=headers)
        runResult = json.loads(str(r.text))
        print (runResult['ServiceResponse']['data'][0]['WasScan']['status'])
        if str(runResult['ServiceResponse']['data'][0]['WasScan']['status']) == "FINISHED":
            scanRunning = False
        else:
            time.sleep(20)

def reportVulnWebApp(headers,URL,scanWebAppId):
    checkVulnStatusWebApp(headers,URL,scanWebAppId)
    reportVulnWebAppURL = URL + "/qps/rest/3.0/download/was/wasscan/" + str(scanWebAppId)
    reportVulnWebAppName="Azure-DevOps-CI-Scan-Report-" + str(webAppId)
    try:
        r = requests.get(reportVulnWebAppURL, headers=headers)
        runResult = json.loads(str(r.text))
        if str(runResult['ServiceResponse']['responseCode']) == "SUCCESS":
            sevFiveVuln = runResult['ServiceResponse']['data'][0]['WasScan']['stats']['global']['nbVulnsLevel5']
            sevFourVuln = runResult['ServiceResponse']['data'][0]['WasScan']['stats']['global']['nbVulnsLevel4']
            sevThreeVuln = runResult['ServiceResponse']['data'][0]['WasScan']['stats']['global']['nbVulnsLevel3']
            return sevFiveVuln,sevFourVuln,sevThreeVuln
        else:
            print (runResult['ServiceResponse']['responseCode'], runResult['ServiceResponse']['responseErrorDetails']['errorMessage'])
    except IOError as e:
        print("Error {0}: {1}".format(e.errno, e.strerror))
        
if __name__ == "__main__":
    webAppId = createAuthRecord(headers,URL,webAppUserName,webAppPassWord,webAppURL,ProfileId)
    scanWebAppId = scanWebApp(headers,URL,webAppId)
    sevFiveVuln,sevFourVuln,sevThreeVuln = reportVulnWebApp(headers,URL,scanWebAppId)
    if (sevFiveVuln > 0 or sevFourVuln > 0 or sevThreeVuln > 0):
        print ("There are vulnerabilities of sev5:{0},se4:{1},sev3:{2}".format(sevFiveVuln,sevFourVuln,sevThreeVuln))
        sys.exit(1)
        
