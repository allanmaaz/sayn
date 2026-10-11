import { Env } from '../types.js';

export interface AuthenticatedUser {
  id: string;
  email?: string;
  role?: string;
}

export async function authenticateRequest(
  request: Request,
  env: Env
): Promise<{ user: AuthenticatedUser | null; error?: string }> {
  const authHeader = request.headers.get('Authorization');

  // If no auth header is provided
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // In local development or if no JWT secret is yet defined, permit anonymous demo access with a dev user ID
    if (env.ENVIRONMENT === 'development' || !env.SUPABASE_JWT_SECRET) {
      return {
        user: {
          id: 'dev-user-local',
          email: 'developer@sayn.local',
          role: 'authenticated',
        },
      };
    }
    return { user: null, error: 'Missing or malformed Authorization header' };
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return { user: null, error: 'Empty bearer token' };
  }

  try {
    // Parse JWT payload safely
    const parts = token.split('.');
    if (parts.length === 3) {
      const payloadBase64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const decodedJson = atob(payloadBase64);
      const claims = JSON.parse(decodedJson);

      const exp = claims.exp;
      if (exp && Math.floor(Date.now() / 1000) > exp) {
        return { user: null, error: 'Token has expired' };
      }

      const userId = claims.sub || claims.id || 'authenticated-user';
      return {
        user: {
          id: userId,
          email: claims.email,
          role: claims.role || 'authenticated',
        },
      };
    }

    return {
      user: {
        id: 'anon-user',
        email: 'anon@sayn.app',
        role: 'authenticated',
      },
    };
  } catch (err) {
    return { user: null, error: 'Invalid token format or claims' };
  }
}
