-- Make the secret in github account settings, developer settings
--, a fine-grained PAT with contents:read_only
CREATE OR REPLACE SECRET git_secret
  TYPE = password
  USERNAME = 'EvanWAppel'
  PASSWORD = 'PAT';
-- Create the integration
CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/EvanWAppel/elvis.git')
  ALLOWED_AUTHENTICATION_SECRETS = (git_secret)
  ENABLED = TRUE;
-- Create the repository object
CREATE OR REPLACE GIT REPOSITORY my_git_repo
  API_INTEGRATION = git_api_integration
  GIT_CREDENTIALS = git_secret
  ORIGIN = 'https://github.com/EvanWAppel/elvis.git';

-- If you're an idiot and set the permissions on the git PAT to be read only...
ALTER SECRET git_secret
  SET PASSWORD = 'PAT';

