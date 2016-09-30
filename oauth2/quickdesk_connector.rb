{
  title: "QuickDesk",

  connection: {
    authorization: {
      type: "oauth2",

      authorization_url: lambda do
        "https://api.quickcloud.io/core/v1/oauth2/authorize?response_type=code"
      end,

      token_url: lambda do
        "https://api.quickcloud.io/core/v1/oauth2/token"
      end,

      client_id: "YOUR_CLIENT_ID",

      client_secret: "YOUR_CLIENT_SECRET",

      credentials: lambda do |_connection, access_token|
        headers(Authorization: "Bearer #{access_token}")
      end,
    }
  },

  object_definitions: {
    lead: {
      fields: lambda do
        [
          { name: "objectId" },
          { name: "name" },
          { name: "email" },
        ]
      end
    }
  },

  triggers: {
    leads_exported: {
      input_fields: lambda do |_object_definitions|
        [
          { name: "service", control_type: "select", pick_list: "service" }
        ]
      end,

      webhook_subscribe: lambda do |webhook_url, _connection, input, flow_id|
        post("https://api.quickcloud.io/core/v1/webhooks",
          name: "Workato recipe #{flow_id}",
          callbackURL: webhook_url,
          resource: "leads",
          event: "export",
          service: input["service"]
        )
      end,

      webhook_notification: lambda do |_input, payload|
        payload["leads"]
      end,

      webhook_unsubscribe: lambda do |webhook|
        delete("https://api.quickcloud.io/core/v1/webhooks/#{webhook['objectId']}",
          callbackURL: webhook['callbackURL'],
          resource: webhook['resource'],
          event: webhook['event'],
          service: webhook['service']
        )
      end,

      dedup: lambda do |lead|
        lead["objectId"] + "@" + lead["email"]
      end,

      output_fields: lambda do |object_definitions|
        object_definitions["lead"]
      end,
    },
  },

  pick_lists: {
    service: lambda do |_connection|
      [
        ['MailChimp', 'mailchimp']
      ]
    end
  },
}
