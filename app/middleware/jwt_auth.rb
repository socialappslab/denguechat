# NOTE: This is the long-term solution to using JwtAuth. For now,
# we will decode and encode in the controller.
# See: https://auth0.com/blog/ruby-authentication-secure-rack-apps-with-jwt/
# class JwtAuth
#   def initialize app
#     @app = app
#   end
#
#   def call(env)
#     begin
#       bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
#       payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
#
#       env[:scopes] = payload['scopes']
#       env[:user]   = payload['user']
#
#       @app.call(env)
#     rescue JWT::DecodeError
#       [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
#     rescue JWT::ExpiredSignature
#       [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
#     rescue JWT::InvalidIssuerError
#       [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
#     rescue JWT::InvalidIatError
#       [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
#     end
#   end
#
# end
