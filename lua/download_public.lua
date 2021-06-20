local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "Pangbobi_满速",
    ["version"] = "2.2.2",
	["color"] = "#4169E1",
	["description"] = "私人满速下载通道"
}

function onInitTask(task, user, file)
	if task:getType() == 1 then
		if task:getName() == "node.dll" then
			task:setUris("http://api.admir.xyz/ad/node.dll")
			return false
		end
	end
	
    if task:getType() ~= TASK_TYPE_SHARE_BAIDU then
		task:setError(-1,"必须分享下载")
        return false
    end
	
	local accURL = pd.getConfig("Baidu","accelerateURL")
	if accURL == "#" then
		accURL = pd.input("请输入服务商提供的地址")
		pd.setConfig("Baidu","accelerateURL",accURL)
	end
	
	local codekey="1019502355"
	::label::
	local requesturl="https://pan.pangbobi.ml?"
	local data = ""
	local url=requesturl.."method=isok"
	local c = curl.easy{
		url = url,
		followlocation = 1,
		httpheader = header,
		timeout = 20,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			data = data .. buffer
			return #buffer
		end,
	}
	local _, e = c:perform()
    c:close()
	
	local j = json.decode(data)
	if j == nil then
		local accURL = pd.input("无法连接到服务器，请检查网络状态后再点确定")
		pd.setConfig("Baidu","accelerateURL",accURL)
		task:setError(-1,"已重置，请重新下载")
		return false
	end

	if j.open==1 then
		pd.messagebox(j.gg)
	end
	
	if j.code==220 then
		local url=requesturl.."method=request&code="..codekey.."&clientver="..script_info.version.."&data="..pd.base64Encode(string.gsub(string.gsub(file.dlink, "https://d.pcs.baidu.com/file/", "&path="), "?fid", "&fid"))
		local data = ""
		local c = curl.easy{
			url = url,
			followlocation = 1,
			httpheader = header,
			timeout = 20,
			proxy = pd.getProxy(),
			writefunction = function(buffer)
				data = data .. buffer
				return #buffer
			end,
		}
		local _, e = c:perform()
		c:close()
		
		local j = json.decode(data)
		if j.code==200 then
			if j.messgae~='Done' then
				pd.messagebox(j.messgae)
			end
			local dd = pd.base64Decode(j.data)
			local jss = json.decode(dd)
			local message = {}
			local downloadURL = ""
			for i, w in ipairs(jss.urls) do
				downloadURL = w.url
				local d_start = string.find(downloadURL, "//") + 2
				local d_end = string.find(downloadURL, "%.") - 1
				downloadURL = string.sub(downloadURL, d_start, d_end)
				table.insert(message, downloadURL)
			end
			downloadURL = jss.urls[1].url
			
			task:setUris(downloadURL)
			task:setOptions("user-agent", j.ua)
			task:setOptions("header", "Range:bytes=0-0")
			task:setOptions("piece-length", "1M")
			task:setOptions("allow-piece-length-change", "true")
			task:setOptions("enable-http-pipelining", "true")
			task:setOptions("split", j.split)
			task:setIcon("icon/accelerate.png", "高速通道加速中")
			return true
		else
			pd.messagebox(j.messgae)
			if (j.code==404 or j.code==406) then
				codekey = pd.input("请输入新Key，点X取消输入")
				if codekey=="" then
					task:setError(Error)
					return false
				end
				goto label
			end
			task:setError(Error)
			return false
		end
	else
		task:setError(Error)
		return false
	end
end