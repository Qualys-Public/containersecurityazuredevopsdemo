$Username = $(QUALYS_USERNAME) #Create as Pipeline Variable
$Password = $(QUALYS_PASSWORD) #Create as Pipeline Variable
$URL = $(QUALYS_API_SERVER) #Create as Pipeline Variable
$ProfileId = $(QUALYS_WAS_ProfileId) #Create as Pipeline Variable
$webAppUserName = $(WEBAPP_USERNAME) #Create as Pipeline Variable
$webAppPassWord = $(WEBAPP_PASSWORD) #Create as Pipeline Variable
$webAppURL = $(webAppURL.AppServiceApplicationUrl) #pass it as a variable from QA Slot
$emailAdd1 = $(QUALYS_WAS_emailAdd1) #Email address for reporting
$templateId = $(QUALYS_WAS_templateId) #Report Template
$scanReportPassword = $(QUALYS_WAS_scanReportPassword)



add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

$AllProtocols = [System.Net.SecurityProtocolType]'Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

function main()
{
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))
		$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headers.Add("X-Requested-With", "Qualys")
		$headers.Add("Content-Type", "application/xml")
		$headers.Add("Authorization",("Basic {0}" -f $base64AuthInfo))

        #Create Web Authentication Record
        $authRecordName = "Default" + $(date)
		$authRecordURI = $URL + "/qps/rest/3.0/create/was/webappauthrecord/"
        $authRecordbody= @"
        <ServiceRequest>
         <data>
         <WebAppAuthRecord>
             <name><![CDATA[$authRecordName]]></name>
             <formRecord>
                 <type>STANDARD</type>
                 <sslOnly>true</sslOnly>
                 <fields>
                     <set>
                         <WebAppAuthFormRecordField>
                             <name>username</name>
                             <value>$webAppUserName</value>
                         </WebAppAuthFormRecordField>
                         <WebAppAuthFormRecordField>
                             <name>password</name>
                             <value>$webAppPassWord</value>
                         </WebAppAuthFormRecordField>
                     </set>
                 </fields>
             </formRecord>
             <comments>
                 <set>
                    <Comment><contents><![CDATA[somecomments]]></contents></Comment>
                 </set>
             </comments>
         </WebAppAuthRecord>
         </data>
        </ServiceRequest>
"@
        try
        {
            $auth_added= Invoke-WebRequest  -Method Post -Headers $headers -Uri $authRecordURI -Body $authRecordbody
            [xml]$XmlDocument_auth = $auth_added.Content
            $authRecordId = ($XmlDocument_auth.ServiceResponse.data.WebAppAuthRecord.id)
        }
        catch
        {
            If ($_.Exception.Response) {
                $error = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                Write-Output "ErrorCode $error";
                $errordescription = ($_.Exception.Response.StatusDescription).ToString().Trim();
                Write-Output "ErrorDesc $errordescription";  
                $errorMessage = ($_.Exception.Message).ToString().Trim();
                Write-Output "ErrorMsg $errorMessage";
            }

            If  ($_.ErrorDetails.Message) {
                $ResponseBody = ($_.ErrorDetails.Message).ToString().Trim();
                $ResponseBody = $ResponseBody -replace "\s+", " ";
            }
            Write-Output "default $ResponseBody";
        }

        #Create Web Application
        $webApp_name = "Deafult" + $(date)
        $webAppCreateURI=$URL + "/qps/rest/3.0/create/was/webapp/"
        $webAppCreateBody=@"
        <ServiceRequest>
         <data>
         <WebApp>
             <name><![CDATA[$webApp_name]]></name>
              <url><![CDATA[$webAppURL]]></url>
             <authRecords>
                 <set>
                    <WebAppAuthRecord>
                        <id>$authRecordId</id>
                    </WebAppAuthRecord>
                 </set>
             </authRecords>
             <defaultProfile>
                <id>$ProfileId</id>
             </defaultProfile>
             <defaultScanner>
                <type>EXTERNAL</type>
             </defaultScanner>
         </WebApp>
         </data>
        </ServiceRequest>

"@
        try
        {
            $webApp_added= Invoke-WebRequest  -Method Post -Headers $headers -Uri $webAppCreateURI -Body $webAppCreateBody  
            [xml]$XmlDocument_webApp = $webApp_added.Content
            $webAppId = ($XmlDocument_webApp.ServiceResponse.data.WebApp.id)
        }
        catch
        {
            If ($_.Exception.Response) {
                $error = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                Write-Output "ErrorCode $error";
                $errordescription = ($_.Exception.Response.StatusDescription).ToString().Trim();
                Write-Output "ErrorDesc $errordescription";  
                $errorMessage = ($_.Exception.Message).ToString().Trim();
                Write-Output "ErrorMsg $errorMessage";
            }

            If  ($_.ErrorDetails.Message) {
                $ResponseBody = ($_.ErrorDetails.Message).ToString().Trim();
                $ResponseBody = $ResponseBody -replace "\s+", " ";
            }
            Write-Output "default $ResponseBody";
        }

        #Launch Scan on WebApp
        $scanName = "ScaninAzureDevOps-" + $(date)        
        $webAppCreateURI=$URL + "/qps/rest/3.0/launch/was/wasscan/"
        $webAppCreateBody=@"
        <ServiceRequest>
           <data>
              <WasScan>
                 <name>$scanName</name>
                 <type>VULNERABILITY</type>
                 <target>
                    <webApp>
                       <id>$webAppId</id>
                    </webApp>
                    <webAppAuthRecord>
                       <isDefault>true</isDefault>
                    </webAppAuthRecord>
                    <scannerAppliance>
                       <type>EXTERNAL</type>
                    </scannerAppliance>
                 </target>
                 <profile>
                    <id>$ProfileId</id>
                 </profile>
              </WasScan>
           </data>
        </ServiceRequest>
"@
        try
        {
            $webApp_added= Invoke-WebRequest -Method Post -Headers $headers -Uri $webAppCreateURI -Body $webAppCreateBody
            [xml]$XmlDocument_webapp_scan = $webApp_added.Content
            $webAppScanId = ($XmlDocument_webapp_scan.ServiceResponse.data.WasScan.id)
        }
        catch
        {
            If ($_.Exception.Response) {
                $error = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                Write-Output "ErrorCode $error";
                $errordescription = ($_.Exception.Response.StatusDescription).ToString().Trim();
                Write-Output "ErrorDesc $errordescription";  
                $errorMessage = ($_.Exception.Message).ToString().Trim();
                Write-Output "ErrorMsg $errorMessage";
            }

            If  ($_.ErrorDetails.Message) {
                $ResponseBody = ($_.ErrorDetails.Message).ToString().Trim();
                $ResponseBody = $ResponseBody -replace "\s+", " ";
            }
            Write-Output "default $ResponseBody";
        }
        #Check status of Vulnerability scan launched on Web Application
        $webApp_scan_status_URI=$URL + "/qps/rest/3.0/status/was/wasscan/" + $webAppScanId
        Do
        {
            Start-Sleep -s 20
            $webApp_scanned_status = Invoke-WebRequest  -Method GET -Headers $headers -Uri $webApp_scan_status_URI
            [xml]$XmlDocument1 = $webApp_scanned_status.Content
            $scanstate = $XmlDocument1.ServiceResponse.data.WasScan.status
            echo $scanstate
        } While ($scanstate -ne "FINISHED") 

        #get result of Vulnerability scan launched on Web Application
        $webApp_scan_result_URI=$URL + "/qps/rest/3.0/download/was/wasscan/" + $webAppScanId
        try
		{
			$scanResult = Invoke-WebRequest  -Method GET -Headers $headers -Uri $webApp_scan_result_URI
			[xml]$XmlDocument3 =$scanResult.Content
            $Sev5= ($XmlDocument3.WasScan.stats.global.nbVulnsLevel5)
            echo $Sev5
            $Sev4= ($XmlDocument3.WasScan.stats.global.nbVulnsLevel4)
            echo $Sev4
            $Sev3= ($XmlDocument3.WasScan.stats.global.nbVulnsLevel3)
            echo $Sev3
            if ([INT]$Sev4 -gt 0 -or [INT]$Sev5 -gt 0 -or [INT]$Sev3 -gt 0){
            Write-Host  "##vso[task.LogIssue type=error;]This is the error"
            exit 1
            }
		}
        catch
        {
            If ($_.Exception.Response) {
                $error = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                Write-Output "ErrorCode $error";
                $errordescription = ($_.Exception.Response.StatusDescription).ToString().Trim();
                Write-Output "ErrorDesc $errordescription";  
                $errorMessage = ($_.Exception.Message).ToString().Trim();
                Write-Output "ErrorMsg $errorMessage";
            }

            If  ($_.ErrorDetails.Message) {
                $ResponseBody = ($_.ErrorDetails.Message).ToString().Trim();
                $ResponseBody = $ResponseBody -replace "\s+", " ";
            }
            Write-Output "default $ResponseBody";
        }
        
        #Create and send Web Scan Report
        $scanReportName = "Default-Scan-Report-" + $(date)
		$scanReportURI = $URL + "/qps/rest/3.0/create/was/report/"
        $scanReportbody= @"
        <ServiceRequest>
         <data>
         <Report>
         <name><![CDATA[$scanReportName]]></name>
         <format>PDF_ENCRYPTED</format>
         <password>$scanReportPassword</password>
         <template>
         <id>$templateId</id>
         </template>
         <config>
         <scanReport>
         <target>
         <scans>
         <WasScan>
         <id>$webAppScanId</id>
         </WasScan>
         </scans>
         </target>
         </scanReport>
         </config>
         </Report>
         </data>
        </ServiceRequest>
"@
        try
        {
            $scan_report_added= Invoke-WebRequest  -Method Post -Headers $headers -Uri $scanReportURI -Body $scanReportbody
            [xml]$XmlDocument_scan_report = $scan_report_added.Content
            $scanReportId = ($XmlDocument_scan_report.ServiceResponse.data.Report.id)
        }
        catch
        {
            If ($_.Exception.Response) {
                $error = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                Write-Output "ErrorCode $error";
                $errordescription = ($_.Exception.Response.StatusDescription).ToString().Trim();
                Write-Output "ErrorDesc $errordescription";  
                $errorMessage = ($_.Exception.Message).ToString().Trim();
                Write-Output "ErrorMsg $errorMessage";
            }

            If  ($_.ErrorDetails.Message) {
                $ResponseBody = ($_.ErrorDetails.Message).ToString().Trim();
                $ResponseBody = $ResponseBody -replace "\s+", " ";
            }
            Write-Output "default $ResponseBody";
        }
        sleep 30
        $sendReportURI = $URL + "/qps/rest/3.0/send/was/report/" + $scanReportId
        $sendReportbody= @"
         <ServiceRequest>
         <data>
         <Report>
         <distributionList>
         <add>
         <EmailAddress><![CDATA[$emailAdd1]]></EmailAddress>
         </add>
         </distributionList>
         </Report>
         </data>
         </ServiceRequest>
"@
        try
        {
            $send_report_initiated= Invoke-WebRequest  -Method Post -Headers $headers -Uri $sendReportURI -Body $sendReportbody

        }
        catch
        {
            If ($_.Exception.Response) {
                $error = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                Write-Output "ErrorCode $error";
                $errordescription = ($_.Exception.Response.StatusDescription).ToString().Trim();
                Write-Output "ErrorDesc $errordescription";  
                $errorMessage = ($_.Exception.Message).ToString().Trim();
                Write-Output "ErrorMsg $errorMessage";
            }

            If  ($_.ErrorDetails.Message) {
                $ResponseBody = ($_.ErrorDetails.Message).ToString().Trim();
                $ResponseBody = $ResponseBody -replace "\s+", " ";
            }
            Write-Output "default $ResponseBody";
        }
}
main
