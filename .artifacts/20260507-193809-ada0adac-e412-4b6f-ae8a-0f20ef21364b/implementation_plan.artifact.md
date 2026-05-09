# Updating Login and Sign Up Screens with Animated GIFs

The user wants to replace the static images on the login and sign-up screens with an animated GIF (`logo_join_animation.gif`) found in the `assets/` folder.

## Proposed Changes

### Assets

#### [pubspec.yaml](file:///C:/Users/USER/StudioProjects/Connevo/pubspec.yaml)
- Add `assets/logo_join_animation.gif` to the assets list.

### Screens

#### [UserLoginScreen](file:///C:/Users/USER/StudioProjects/Connevo/lib/auth/screen/user-login-screen.dart)
- Replace `assets/log-in.jpg` with `assets/logo_join_animation.gif`.
- Adjust the `BoxFit` to `BoxFit.contain` for better GIF display if needed.

#### [SignUpScreen](file:///C:/Users/USER/StudioProjects/Connevo/lib/auth/screen/signup.dart)
- Replace `assets/auth_signup.png` with `assets/logo_join_animation.gif`.
- Ensure it uses `BoxFit.contain` as requested implicitly by the previous change.

## Verification Plan

### Manual Verification
- Run the app and navigate to the Login screen.
- Verify the GIF is playing correctly at the top.
- Navigate to the Sign Up screen.
- Verify the same GIF is playing correctly at the top.
