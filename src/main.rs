use bevy::prelude::*;

fn main() {
    App::new()
        // Plugins Bevy par défaut (fenêtre, rendu, input, etc.)
        .add_plugins(DefaultPlugins)
        // Notre système de setup (lance une seule fois au démarrage)
        .add_systems(Startup, setup)
        // Nos systèmes de gameplay (tournent chaque frame)
        .add_systems(Update, (move_player, rotate_player))
        .run();
}

// === COMPONENTS (les données) ===

#[derive(Component)]
struct Player;

#[derive(Component)]
struct Velocity {
    x: f32,
    y: f32,
}

// === SYSTEMS (la logique) ===

/// System de setup : spawn le joueur
fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
) {
    // Spawner la caméra 2D
    commands.spawn(Camera2d);

    // Spawner le joueur (un carré rouge)
    commands.spawn((
        Player,
        Velocity { x: 0.0, y: 0.0 },
        Mesh2d(meshes.add(Rectangle::new(50.0, 50.0))),
        MeshMaterial2d(materials.add(Color::srgb(1.0, 0.0, 0.0))),
        Transform::from_xyz(0.0, 0.0, 0.0),
    ));
}

/// System : déplacer le joueur avec ZQSD/Flèches
fn move_player(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mut query: Query<(&mut Transform, &mut Velocity), With<Player>>,
    time: Res<Time>,
) {
    for (mut transform, mut velocity) in query.iter_mut() {
        let speed = 200.0;

        // Reset velocity
        velocity.x = 0.0;
        velocity.y = 0.0;

        // Input
        if keyboard_input.pressed(KeyCode::KeyW) || keyboard_input.pressed(KeyCode::ArrowUp) {
            velocity.y += speed;
        }
        if keyboard_input.pressed(KeyCode::KeyS) || keyboard_input.pressed(KeyCode::ArrowDown) {
            velocity.y -= speed;
        }
        if keyboard_input.pressed(KeyCode::KeyA) || keyboard_input.pressed(KeyCode::ArrowLeft) {
            velocity.x -= speed;
        }
        if keyboard_input.pressed(KeyCode::KeyD) || keyboard_input.pressed(KeyCode::ArrowRight) {
            velocity.x += speed;
        }

        // Appliquer le mouvement
        transform.translation.x += velocity.x * time.delta_secs();
        transform.translation.y += velocity.y * time.delta_secs();
    }
}

/// System : rotation automatique du joueur
fn rotate_player(
    mut query: Query<&mut Transform, With<Player>>,
    time: Res<Time>,
) {
    for mut transform in query.iter_mut() {
        transform.rotation *= Quat::from_rotation_z(time.delta_secs() * 2.0);
    }
}