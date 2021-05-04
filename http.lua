function download(url, fileName, finishedCallback)
    print("- Downloading from: '"..url.."' and writing to '"..fileName.."'")

    -- TODO: could this handle credentials and HTTPS => passwords etc. could be secured this way
    http.get(url, nil, function(code, data)
      if code==200 then
        print("- HTTP request for OTA succeeded. Writing '"..fileName.."'")
        
        if file.open(fileName, "w+") then
          file.write(data)
          file.close()
          print("- written '"..fileName.."'")
        else
          print("- error writing '"..fileName.."'")
        end
        
        firstWifiConnection = false
      else
        print("- HTTP request for '"..url.."' failed.")
      end
  
      finishedCallback()
    end)
  end
  