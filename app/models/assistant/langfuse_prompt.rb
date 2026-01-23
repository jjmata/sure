module Assistant::LangfusePrompt
  extend ActiveSupport::Concern

  PROMPT_NAME = "default_instructions".freeze
  CACHE_KEY_PREFIX = "langfuse_prompt".freeze
  CACHE_TTL = 5.minutes

  PromptResult = Struct.new(:content, :name, :version, :from_langfuse?, keyword_init: true)

  class_methods do
    def fetch_langfuse_prompt(variables: {})
      return nil unless langfuse_configured?

      cached_prompt = read_cached_prompt
      return compile_prompt(cached_prompt, variables) if cached_prompt

      fetch_and_cache_prompt(variables)
    rescue => e
      Rails.logger.warn("[LangfusePrompt] Failed to fetch prompt: #{e.message}")
      nil
    end

    def langfuse_configured?
      ENV["LANGFUSE_PUBLIC_KEY"].present? && ENV["LANGFUSE_SECRET_KEY"].present?
    end

    private
      def langfuse_client
        @langfuse_client ||= Langfuse.new
      end

      def fetch_and_cache_prompt(variables)
        prompt = langfuse_client.get_prompt(PROMPT_NAME)
        return nil unless prompt

        cache_prompt(prompt)
        compile_prompt(prompt, variables)
      rescue => e
        Rails.logger.warn("[LangfusePrompt] Error fetching prompt '#{PROMPT_NAME}': #{e.message}")
        nil
      end

      def compile_prompt(prompt, variables)
        compiled_content = if variables.any?
          prompt.compile(**variables)
        else
          prompt.prompt
        end

        PromptResult.new(
          content: compiled_content,
          name: prompt.name,
          version: prompt.version,
          from_langfuse?: true
        )
      end

      def cache_key
        "#{CACHE_KEY_PREFIX}/#{PROMPT_NAME}"
      end

      def cache_prompt(prompt)
        Rails.cache.write(cache_key, prompt, expires_in: CACHE_TTL)
      end

      def read_cached_prompt
        Rails.cache.read(cache_key)
      end
  end
end
