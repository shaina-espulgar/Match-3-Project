local test, testAssert, testError

local function createNode (parent, description, process)
    return setmetatable({
        parent = parent,
        description = description,
        process = process,
        nodes = {},
        activeNodeIndex = 1,
        currentNodeIndex = 0,
        assert = testAssert,
        error = testError,
    }, { __call = test })
end

local function runNode (node)
    node.currentNodeIndex = 0
    return node:process()
end

local function getRootNode (node)
    local parent = node.parent
    return parent and getRootNode(parent) or node
end

local function updateActiveNode (node, description, process)
    local activeNodeIndex = node.activeNodeIndex
    local nodes = node.nodes
    local activeNode = nodes[activeNodeIndex]

    if not activeNode then
        activeNode = createNode(node, description, process)
        nodes[activeNodeIndex] = activeNode
    else
        activeNode.process = process
    end

    getRootNode(node).lastActiveLeaf = activeNode

    return activeNode
end

local function runActiveNode (node, description, process)
    local activeNode = updateActiveNode(node, description, process)
    return runNode(activeNode)
end

local function getAncestors (node)
    local ancestors = { node }
    for ancestor in function () return node.parent end do
        ancestors[#ancestors + 1] = ancestor
        node = ancestor
    end
    return ancestors
end

local function printScenario (node)
    local ancestors = getAncestors(node)
    for i = #ancestors, 1, -1 do
        io.stderr:write(ancestors[i].description or '')
        io.stderr:write('\n')
    end
end

local function failAssert (node, description, message)
    io.stderr:write(message or '')
    io.stderr:write('\n\n')
    printScenario(node)
    io.stderr:write(description or '')
    io.stderr:write('\n\n')
    error(message or '', 2)
end

test = function (node, description, process)
    node.currentNodeIndex = node.currentNodeIndex + 1
    if node.currentNodeIndex == node.activeNodeIndex then
        return runActiveNode(node, description, process)
    end
end

testAssert = function (self, value, description)
    if not value then
        return failAssert(self, description, 'Test failed: assertion failed')
    end
    return value
end

testError = function (self, f, description)
    if pcall(f) then
        return failAssert(self, description, 'Test failed: expected error')
    end
end

local function T (description, process)
    local root = createNode(nil, description, process)

    runNode(root)
    while root.activeNodeIndex <= #root.nodes do
        local lastActiveBranch = root.lastActiveLeaf.parent
        lastActiveBranch.activeNodeIndex = lastActiveBranch.activeNodeIndex + 1
        runNode(root)
    end

    return root
end

if arg and arg[0] and arg[0]:gmatch('test.lua') then
    _G.T = T
    for i = 1, #arg do
        dofile(arg[i])
    end
    _G.T = nil
end

return T
