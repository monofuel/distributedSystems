require('schema')

-- Key Value Store

KV_Schema = {
    ['type'] = "KV",
    ['fields'] = {
        {
            ['name'] = 'collection',
            ['id'] = 1,
            ['repeated'] = true,
            ['type'] = {
                ['type'] = 'entry',
                ['fields'] = {
                    {
                        ['name'] = "key",
                        ["id"] = 1,
                        ["type"] = "string"
                    },
                    {
                        ['name'] = "value",
                        ["id"] = 2,
                        ["type"] = "any"
                    }
                }
            }
        }
    }
}
validateSchema(KV_Schema)

