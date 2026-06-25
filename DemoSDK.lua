--!strict
-- Open Cloud Luau Execution SDK
-- Source: github.com/Roblox/open-cloud-execution-binary-payloads-example

local Http = require("@lune/http")
local Json = require("@lune/json")
local Base64 = require("@lune/base64")

export type TaskResult = {
    state: string,
    returns: any,
    logs: { string },
    error: string?
}

export type CreateTaskOpts = {
    script: string,
    binaryInputs: { string }?,
    maxLogLines: number?,
    timeout: number?
}

local function createTask(uid: number, pid: number, key: string, opts: CreateTaskOpts): (boolean, any)
    local url = string.format("https://apis.roblox.com/cloud/v2/universes/%d/places/%d/luau-execution-session-tasks", uid, pid)
    local body = {
        script = opts.script,
        binaryInputs = opts.binaryInputs,
        maxLogLines = opts.maxLogLines or 100,
        timeout = opts.timeout or 300
    }
    
    local res = Http.post(url, {
        headers = {
            ["x-api-key"] = key,
            ["Content-Type"] = "application/json"
        },
        body = Json.stringify(body)
    })
    
    if res.status ~= 200 then
        return false, res.body
    end
    
    return true, Json.parse(res.body)
end

local function getTask(uid: number, pid: number, key: string, sid: string, tid: string): (boolean, TaskResult?)
    local url = string.format("https://apis.roblox.com/cloud/v2/universes/%d/places/%d/luau-execution-sessions/%s/tasks/%s", uid, pid, sid, tid)
    
    local res = Http.get(url, {
        headers = { ["x-api-key"] = key }
    })
    
    if res.status ~= 200 then
        return false, nil
    end
    
    return true, Json.parse(res.body)
end

local function getLogs(uid: number, pid: number, key: string, sid: string, tid: string): (boolean, { string }?)
    local url = string.format("https://apis.roblox.com/cloud/v2/universes/%d/places/%d/luau-execution-sessions/%s/tasks/%s/logs", uid, pid, sid, tid)
    
    local res = Http.get(url, {
        headers = { ["x-api-key"] = key }
    })
    
    if res.status ~= 200 then
        return false, nil
    end
    
    local data = Json.parse(res.body)
    return true, data.logs or {}
end

local function createBinaryInput(uid: number, key: string, file: string): (boolean, string?)
    local url = string.format("https://apis.roblox.com/cloud/v2/universes/%d/luau-execution-session-task-binary-inputs", uid)
    
    local fileData = io.readFile(file)
    local b64 = Base64.encode(fileData)
    
    local res = Http.post(url, {
        headers = {
            ["x-api-key"] = key,
            ["Content-Type"] = "application/octet-stream"
        },
        body = fileData
    })
    
    if res.status ~= 200 then
        return false, nil
    end
    
    local data = Json.parse(res.body)
    return true, data.binaryInputId
end

return {
    createTask = createTask,
    getTask = getTask,
    getLogs = getLogs,
    createBinaryInput = createBinaryInput
}
