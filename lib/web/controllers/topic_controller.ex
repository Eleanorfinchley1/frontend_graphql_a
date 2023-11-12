defmodule Web.TopicController do
    use Web, :controller

    alias BillBored.Topics
    action_fallback Web.FallbackController
    def get(conn, _params) do
        topic = Topics.get_topics()
        render(conn, "show.json", topic: topic)
    end

end