local curl = require "lcurl.safe"
local json = require "cjson.safe"

script_info = {
	["title"] = "度盘搜(搜资源)",
	["version"] = "0.0.2",
	["color"] = "#008B00",
	["description"] = "Beta Version"
}

function onSearch(key, page)
	local data = ""
	local c = curl.easy{
		url = "https://admirecn.de/blog/ad/cdn2.php?key=" .. pd.urlEncode(key).. "&page=" .. page,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			data = data .. buffer
			return #buffer
		end,
	}
	
	local _, e = c:perform()
	if e then
        return false
    end
	c:close()
	return parse(data)
end

function onItemClick(item)
	return ACT_SHARELINK, item.url 
end


function parse(data)
	local result = {}
	local test = string.sub(data,1,string.len(data)-4)
	pd.logInfo(test)
	local j = json.decode(test)
	
	if j == nil then
        return false
    end
	
	for i, w in ipairs(j.data) do
		local tooltip = w.title
        table.insert(result, {["url"] = "https://pan.baidu.com/s/"..w.surl, ["title"] = w.title, ["time"] = time, ["showhtml"] = "true", ["tooltip"] = tooltip, ["check_url"] = "true"})
    end
	return result
end