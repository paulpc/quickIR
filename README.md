# quickIR
IR scripts in PowerShell and the associated ELK configurations 

#How to use this
The quickest way to get started is to try out the latest version of the ELK SuseStudio image at: https://susestudio.com/a/YFDShO/elasticsearchlogstashkibana

If you want to try it on your own infrastructure here are some helpful files:
- quickIR.ps1: powershell script to send telemetry data to ELK. Make sure to update the Logstash server ip: `$serverIP = "[the IP of this VM]"`
- kibana.yml: kibana config example. Make sure to have the right source port.
- kibana.service: systemd configuration to set up a kibana service. Please make sure to set the apropriate location for the kibana executable: `ExecStart=/opt/kibana/bin/kibana`
- logstash.conf: configuration file for logstash to listen on 1514 and store the results in the ioc_v2 index or the executables index
- Microsoft.PowerShellISE_profile.ps1 and Microsoft.PowerShell_profile.ps1 are sample profile files for powershell to be used on the responder's machine. You can just add the function to your profile if you have a profile already, just make sure to *change* `(New-Object System.Net.Webclient).DownloadString('http://[change me]/quickIR.ps1')}` to have the IP of the ELK server (or whatever server you have to host the quickIR.ps1 file).

To get you started, I included some sample data in the ./sample folder. Set the logstash server in `TCP_IP = '127.0.0.1'` and the logstash port in `TCP_PORT = 1514`. You can just run the python file to pre-populate the ioc_v2 index.

We also included a sample Kibana dashboard and searches to go with it in kibana_example.json. Go to Settings > Objects > Import to load it in your Kibana Instance.
