use bevy::prelude::*;
use bevy::render::camera::ViewportConversionError;

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
    windows: Query<&Window>,
    camera_query: Query<(&Camera, &GlobalTransform)>,
) {
    if buttons.pressed(MouseButton::Left) {
        if let Ok(window) = windows.get_single() {
            let mut square = square_query.single_mut();
            let (camera, camera_transform) = camera_query.single();

            if let Some(cursor_position) = window.cursor_position() {
                if let Ok(camera_position) =
                    camera.viewport_to_world_2d(camera_transform, cursor_position)
                {
                    square.translation.x = camera_position.x;
                    square.translation.y = camera_position.y;
                }
            }
        }
    }
}

#[derive(Component)]
struct Square;
