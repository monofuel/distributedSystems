
-- schema upgrading

-- types: nil, boolean, integer, double, string, table
-- schema values can be `repeated` (arrays)

-- tagged unions?
-- constraints?
-- required vs optional?

-- schemas can have up to 255 keys
--   hashmaps can be represented as an array of key:value pairs



-- schema nodes are tables
-- {
--   type: 'string', // name of the the schema
--   fields: {
--     -- TOOD required fields
--     -- each ID must be unique!
--     { name: 'string', repeated: boolean, type: 'string', id: number }
--     ... repeated ...
-- 
--   }
-- }
-- type can be a table, for nested schemas

function validateSchema(schema) 
    assert(type(schema) == 'table')
    assert(type(schema['type']) == 'string')

    assert(type(schema['fields']) == 'table')
    assert(schema['fields'][1] ~= nil)
    for k,v in pairs(schema['fields']) do
        assert(type(k) == 'number')
        assert(type(v) == 'table')

        assert(type(v['name']) == 'string')

        -- TODO test that IDs are unique
        assert(type(v['id']) == 'number')
        assert(type(v['repeated']) == 'boolean' or v['repeated'] == nil)

        -- TODO validate that type is a valid type
        assert(type(v['type']) == 'string' or type(v['type']) == 'table')

        if (type(v['type']) == 'table') then
            validateSchema(v['type'])
        end
    end
end
