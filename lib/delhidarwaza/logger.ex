defmodule DelhiDarwaza.Logger do
  @moduledoc """
  Structured logging utilities for Delhi Darwaza.

  Provides convenience functions for logging with consistent formatting
  and metadata for trading exchange operations.
  """

  require Logger

  @doc """
  Logs an info message with optional metadata.
  """
  def info(message, metadata \\ []) do
    Logger.info(message, metadata)
  end

  @doc """
  Logs a debug message with optional metadata.
  """
  def debug(message, metadata \\ []) do
    Logger.debug(message, metadata)
  end

  @doc """
  Logs a warning message with optional metadata.
  """
  def warn(message, metadata \\ []) do
    Logger.warning(message, metadata)
  end

  @doc """
  Logs an error message with optional metadata.
  """
  def error(message, metadata \\ []) do
    Logger.error(message, metadata)
  end

  @doc """
  Logs application startup.
  """
  def startup(message \\ "Application starting") do
    Logger.info(message, component: :application, event: :startup)
  end

  @doc """
  Logs application shutdown.
  """
  def shutdown(message \\ "Application shutting down") do
    Logger.info(message, component: :application, event: :shutdown)
  end

  @doc """
  Logs order-related events.
  """
  def order_event(event, message, metadata \\ []) do
    Logger.info(message, Keyword.merge([component: :order, event: event], metadata))
  end

  @doc """
  Logs trade-related events.
  """
  def trade_event(event, message, metadata \\ []) do
    Logger.info(message, Keyword.merge([component: :trade, event: event], metadata))
  end

  @doc """
  Logs order book events.
  """
  def orderbook_event(event, message, metadata \\ []) do
    Logger.debug(message, Keyword.merge([component: :orderbook, event: event], metadata))
  end

  @doc """
  Logs account-related events.
  """
  def account_event(event, message, metadata \\ []) do
    Logger.info(message, Keyword.merge([component: :account, event: event], metadata))
  end

  @doc """
  Logs API requests.
  """
  def api_request(method, path, metadata \\ []) do
    Logger.info("API Request: #{method} #{path}", Keyword.merge([component: :api, event: :request], metadata))
  end

  @doc """
  Logs API responses.
  """
  def api_response(status, path, metadata \\ []) do
    Logger.info("API Response: #{status} #{path}", Keyword.merge([component: :api, event: :response], metadata))
  end
end
