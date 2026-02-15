use bevy::prelude::*;
use bevy::render::camera::ViewportConversionError;
use bevy::tasks::futures_lite::StreamExt;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                resolution: (480.0, 854.0).into(),
                resizable: false,
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, setup)
        .add_systems(Update, move_square_on_click)
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
) {
    commands.spawn(Camera2d);

    commands.spawn((
        Text::new("Bonjour Jul, ca avance bien ! \nEssaie de faire bouger la boule !"),
        TextFont {
            font_size: 20.0,
            ..Default::default()
        },
        Transform::from_xyz(0.0, 300.0, 0.0),
    ));

    commands.spawn((
        Mesh2d(meshes.add(Circle::new(50.0))),
        MeshMaterial2d(materials.add(Color::srgb(255.0, 0.0, 0.0))),
        Square,
    ));
}

fn move_square_on_click(
    mut square_query: Query<&mut Transform, With<Square>>,
    buttons: Res<ButtonInput<MouseButton>>,
    touches: Res<Touches>,
    windows: Query<&Window>,
    camera_query: Query<(&Camera, &GlobalTransform)>,
) {
    let mut square = square_query.single_mut();
    let window = windows.single();
    let (camera, camera_transform) = camera_query.single();

    let position = if buttons.pressed(MouseButton::Left) {
        window.cursor_position()
    } else if let Some(touch) = touches.first_pressed_position() {
        Some(touch)
    } else {
        None
    };

    let Some(screen_position) = position else {
        return;
    };

    let Ok(final_position) = camera.viewport_to_world_2d(camera_transform, screen_position) else {
        return;
    };

    square.translation.x = final_position.x;
    square.translation.y = final_position.y;
}

#[derive(Component)]
struct Square;
