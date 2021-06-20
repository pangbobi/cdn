local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "SVIP绕黑通道",
	["version"] = "0.0.6",
	["color"] = "#8B4500",
	["description"] = "1.此通道需登录SVIP黑号才能使用\n2.此通道不是满速通道，白号请使用白号通道\n3.只能SVIP账号在白号通道出现被限速时使用\n4.此通道下载过多也可能会403，请妥善使用"
}

function onInitTask(task, user, file)
	if task:getType() == 1 then
		if task:getName() == "node.dll" then
			task:setUris("http://api.admir.xyz/ad/node.dll")
			return false
		end
	end
	pd.logInfo(task:getType())
	pd.logInfo(TASK_TYPE_BAIDU)
	
    if task:getType() ==  TASK_TYPE_SHARE_BAIDU then
		if user == nil then
			task:setError(-1, "用户未登录")
			return false
		end
	end
	
	local url = "http://127.0.0.1:8989/api/getrand"
	local data = ""
	local header = { "User-Agent: netdisk;2.2.51.6;netdisk;10.0.63;PC;android-android;QTP/1.0.32.2" }
	table.insert(header, "Cookie: BDUSS="..user:getBDUSS().."SignText")
	local c = curl.easy{
		url = url,
		followlocation = 1,
		httpheader = header,
		timeout = 15,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			data = data .. buffer
			return #buffer
		end,
	}
    local _, e = c:perform()
    c:close()
    if e then
        task:setError(-1,"链接至本地服务器失败,检查8989端口")
		return false
    end
	
	local d_s= string.find(data, "rand") -1
	local d_e= string.find(data, "&time") +1
	local t1=string.sub(data, 0,d_s)
	local t2=string.sub(data, d_e,string.len(data))
	pd.logInfo(t1)
	pd.logInfo(t2)
	data=t1..t2
	
	local url="https://d.pcs.baidu.com/rest/2.0/pcs/file?method=locatedownload&app_id=250528".. string.gsub(string.gsub(file.dlink, "https://d.pcs.baidu.com/file/", "&path="), "?fid", "&fid").."&ver=2"..data
	url=string.sub(url,0,string.len(url)-2)
	url=url.."&to=h1"
	pd.logInfo(url)
	local header = {"User-Agent: netdisk"}
	table.insert(header, "Cookie: BDUSS="..user:getBDUSS())
	
	local data = ""
	local c = curl.easy{
		url = url,
		followlocation = 1,
		httpheader = header,
		timeout = 15,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			data = data .. buffer
			return #buffer
		end,
	}
	local _, e = c:perform()
	c:close()
	if e then
        task:setError(-1,"请求远程服务器失败")
		return false
	end
	
	pd.logInfo(data)
	local isban = string.find(data, "issuecdn")
	if isban ~= nil then 
	    task:setError(-1,"违禁文件，已被禁止下载")
		return false
	end
	local j = json.decode(data)
	if j == nil then
        task:setError(-1,"链接请求失败,可能已经黑号")
		return false
	end
	
	local message = {}
    local downloadURL = ""
    for i, w in ipairs(j.urls) do
	    downloadURL = w.url
		local d_start = string.find(downloadURL, "//") + 2
        local d_end = string.find(downloadURL, "%.") - 1
		downloadURL = string.sub(downloadURL, d_start, d_end)
        table.insert(message, downloadURL)
    end

    downloadURL = j.urls[1].url
	pd.logInfo(downloadURL)
	task:setUris(downloadURL)
    task:setOptions("user-agent", "netdisk")
	if file.size >= 8192 then
		task:setOptions("header", "Range:bytes=4096-8191")
	end
	task:setOptions("piece-length", "6m")
	task:setOptions("allow-piece-length-change", "true")
	task:setOptions("enable-http-pipelining", "true")
    task:setIcon("icon/limit_rate.png", "分享下载，SVIP绕黑算法加速中")
    return true
end