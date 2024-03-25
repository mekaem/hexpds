defmodule Hipdster.Auth.User do
  alias Hipdster.K256
  defstruct [:did, :password_hash, :handle, :signing_key, :rotation_key]
  @type t :: %__MODULE__{
    did: String.t(),
    password_hash: String.t(),
    handle: String.t(),
    signing_key: Hipdster.K256.PrivateKey.t(),
    rotation_key: Hipdster.K256.PrivateKey.t()
  }

  defmodule CreateOpts do
    @moduledoc """
    Options for `Hipdster.Auth.User.create/1`
    Because sometimes the input to create will
    be more complex than just a handle and password
    """
    defstruct [:handle, :password]
    @type t :: %__MODULE__{handle: String.t(), password: String.t()}
  end

  @spec create(String.t(), String.t()) :: Hipdster.Auth.User.t()
  def create(handle, pw) do
    %{did: did, signing_key: signing_key, rotation_key: rotation_key} =
      Hipdster.DidGenerator.generate_did(handle)

    %__MODULE__{
      did: did,
      handle: handle,
      password_hash: Argon2.hash_pwd_salt(pw),
      signing_key: signing_key |> K256.PrivateKey.from_hex(),
      rotation_key: rotation_key |> K256.PrivateKey.from_hex()
    }
    |> tap(&Hipdster.Auth.DB.create_user/1)
  end

  @spec create(Hipdster.Auth.User.CreateOpts.t()) :: Hipdster.Auth.User.t()
  def create(%__MODULE__.CreateOpts{handle: handle, password: pw}) do
    create(handle, pw)
  end

  @spec authenticate(String.t(), String.t()) :: false | Hipdster.Auth.User.t()
  def authenticate(username, pw) do
    with %__MODULE__{password_hash: hash} = user <- Hipdster.Auth.DB.get_user(username),
         true <- Argon2.verify_pass(pw, hash) do
      user
    else
      _ -> false
    end
  end

end