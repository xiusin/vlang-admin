module middlewares

import xiusin.very
import crypto.hmac
import encoding.base64
import crypto.sha256
import config
import json
import services

pub fn auth(mut ctx very.Context) ! {
	if !ctx.path().ends_with('/login') && !ctx.path().starts_with('/uploads')
		&& !ctx.path().starts_with('/manages') {
		token := ctx.req.header.get_custom('x-access-token') or { '' }
		// // todo return error auto stop
		if token.len == 0 {
			println('token.len  = 0')
			ctx.stop()
			ctx.set_status(.forbidden)
			return error('miss token')
		}
		if !auth_verify(token) {
			println('token.no_valid  = 0')
			ctx.stop()
			ctx.set_status(.forbidden)
			return error('no valid token')
		}

		jwt_payload_stringify := base64.url_decode_str(token.split('.')[1])
		jwt_payload := json.decode(services.JwtPayload, jwt_payload_stringify) or {
			ctx.stop()
			ctx.set_status(.not_implemented)
			return error('jwt decode error')
		}

		login_user_id := jwt_payload.sub.int()
		ctx.set('user_id', login_user_id)
		ctx.next()!
		return
	}
	ctx.next()!
}

fn auth_verify(token string) bool {
	if token == '' {
		return false
	}
	token_split := token.split('.')

	signature_mirror := hmac.new(config.get_secret_key().bytes(), '${token_split[0]}.${token_split[1]}'.bytes(),
		sha256.sum, sha256.block_size).bytestr().bytes()

	signature_from_token := base64.url_decode(token_split[2])

	return hmac.equal(signature_from_token, signature_mirror)
}
