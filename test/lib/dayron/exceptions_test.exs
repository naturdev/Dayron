defmodule Dayron.ExceptionsTest do
  use ExUnit.Case, async: true
  
  alias Dayron.{NoResultsError, ServerError, ClientError, ValidationError}
  alias Dayron.{Request, Response}

  describe "NoResultsError" do
    test "creates exception with request details" do
      request = %Request{url: "http://api.example.com/users", method: "GET"}
      error = %NoResultsError{request: request}
      
      assert error.request == request
      assert error.plug_status == 404
    end

    test "generates descriptive message with request info" do
      request = %Request{url: "http://api.example.com/users/123", method: "GET"}
      error = %NoResultsError{request: request}
      message = Exception.message(error)
      
      assert message =~ "expected at least one result but got none"
      assert message =~ "http://api.example.com/users/123"
    end

    test "message handles nil request gracefully" do
      error = %NoResultsError{request: nil}
      message = Exception.message(error)
      
      assert message =~ "expected at least one result but got none"
      assert message =~ "nil"
    end
  end

  describe "ServerError" do
    test "creates exception with request and response" do
      request = %Request{url: "http://api.example.com/users", method: "POST"}
      response = %Response{status_code: 500, body: "Internal Server Error"}
      error = %ServerError{request: request, response: response}
      
      assert error.request == request
      assert error.response == response
    end

    test "generates descriptive message with both request and response" do
      request = %Request{url: "http://api.example.com/users", method: "POST"}
      response = %Response{status_code: 500, body: "Internal Server Error"}
      error = %ServerError{request: request, response: response}
      message = Exception.message(error)
      
      assert message =~ "unexpected response error in request"
      assert message =~ "http://api.example.com/users"
      assert message =~ "Response Body:"
      assert message =~ "Internal Server Error"
    end

    test "message displays structured response body" do
      request = %Request{url: "http://api.example.com/users", method: "POST"}
      response = %Response{status_code: 500, body: %{error: "database error", code: 1234}}
      error = %ServerError{request: request, response: response}
      message = Exception.message(error)
      
      assert message =~ "database error"
      assert message =~ "1234"
    end
  end

  describe "ClientError" do
    test "creates exception with connection failure details" do
      request = %Request{url: "http://api.example.com/users", method: "GET"}
      error = %ClientError{id: "user-123", reason: :econnrefused, request: request}
      
      assert error.id == "user-123"
      assert error.reason == :econnrefused
      assert error.request == request
    end

    test "generates descriptive message for connection refused" do
      request = %Request{url: "http://api.example.com/users", method: "GET"}
      error = %ClientError{reason: :econnrefused, request: request}
      message = Exception.message(error)
      
      assert message =~ "unexpected client error in request"
      assert message =~ "Reason: :econnrefused"
      assert message =~ "http://api.example.com/users"
    end

    test "generates descriptive message for timeout" do
      request = %Request{url: "http://api.example.com/slow-endpoint", method: "GET"}
      error = %ClientError{reason: :connect_timeout, request: request}
      message = Exception.message(error)
      
      assert message =~ "unexpected client error in request"
      assert message =~ "Reason: :connect_timeout"
    end

    test "handles custom error reasons" do
      request = %Request{url: "http://api.example.com/users", method: "GET"}
      error = %ClientError{reason: {:error, "network unreachable"}, request: request}
      message = Exception.message(error)
      
      assert message =~ ~s(Reason: {:error, "network unreachable"})
    end

    test "message handles nil request gracefully" do
      error = %ClientError{reason: :timeout, request: nil}
      message = Exception.message(error)
      
      assert message =~ "unexpected client error"
      assert message =~ "nil"
    end
  end

  describe "ValidationError" do
    test "creates exception with validation failure details" do
      request = %Request{url: "http://api.example.com/users", method: "POST"}
      response = %Response{status_code: 422, body: %{errors: %{name: "can't be blank"}}}
      error = %ValidationError{request: request, response: response}
      
      assert error.request == request
      assert error.response == response
      assert error.plug_status == 400
    end

    test "generates descriptive message with validation errors" do
      request = %Request{url: "http://api.example.com/users", method: "POST"}
      response = %Response{status_code: 422, body: %{errors: %{name: "can't be blank", age: "must be positive"}}}
      error = %ValidationError{request: request, response: response}
      message = Exception.message(error)
      
      assert message =~ "validation error in request"
      assert message =~ "http://api.example.com/users"
      assert message =~ "can't be blank"
      assert message =~ "must be positive"
    end

    test "message displays simple validation error body" do
      request = %Request{url: "http://api.example.com/users", method: "POST"}
      response = %Response{status_code: 422, body: "Invalid input"}
      error = %ValidationError{request: request, response: response}
      message = Exception.message(error)
      
      assert message =~ "validation error in request"
      assert message =~ "Invalid input"
    end
  end

  describe "exception compatibility" do
    test "NoResultsError is an Exception" do
      assert %NoResultsError{} |> is_exception()
    end

    test "ServerError is an Exception" do
      assert %ServerError{} |> is_exception()
    end

    test "ClientError is an Exception" do
      assert %ClientError{} |> is_exception()
    end

    test "ValidationError is an Exception" do
      assert %ValidationError{} |> is_exception()
    end
  end

  describe "plug_status attributes" do
    test "NoResultsError has 404 plug_status" do
      error = %NoResultsError{}
      assert error.plug_status == 404
    end

    test "ValidationError has 400 plug_status" do
      error = %ValidationError{}
      assert error.plug_status == 400
    end

    test "ServerError has no plug_status field" do
      error = %ServerError{}
      refute Map.has_key?(error, :plug_status)
    end

    test "ClientError has no plug_status field" do
      error = %ClientError{}
      refute Map.has_key?(error, :plug_status)
    end
  end

  # Helper function to check if a value is an exception
  defp is_exception(%module{}) do
    function_exported?(module, :message, 1) and
    function_exported?(module, :exception, 1)
  end
end
