-- SCRUM-46 route dev seed profile avatars through the Spring public media endpoint.
update users
set profile_image_url = '/api/v1/media/public?key=' || replace(profile_image_url, '/', '%2F')
where profile_image_url like 'dev/avatars/%';
