use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                resolution: (480.0, 800.0).into(),
                resizable: false,
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, setup)
        .add_systems(Update, move_player)
        .add_systems(Update, move_ball)
        .add_systems(Update, check_collision_player)
        .add_systems(Update,check_collision_bricks)
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ColorMaterial>>,
) {
    commands.spawn(Camera2d);

    commands.spawn((
        Text::new("Casse Brique"),
        TextFont {
            font_size: 20.0,
            ..Default::default()
        },
    ));

    let player_size = Size {
        width: 100.0,
        height: 20.0,
    };

    commands.spawn((
        Mesh2d(meshes.add(Rectangle::new(player_size.width, player_size.height))),
        player_size,
        MeshMaterial2d(materials.add(Color::srgb(255.0, 255.0, 255.0))),
        Player,
        Transform::from_xyz(0.0, -350.0, 0.0),
    ));

    commands.spawn((
        Mesh2d(meshes.add(Circle::new(10.0))),
        MeshMaterial2d(materials.add(Color::srgb(255.0, 255.0, 255.0))),
        Ball,
        Size {
            width: 10.0,
            height: 10.0,
        },
        Velocity { x: 0.0, y: -200.0 },
        Transform::from_xyz(0.0, -200.0, 0.0),
    ));

    let rows = 5;
    let cols = 6;

    let spacing = 2.0;

    let start_x_position = -180.0;
    let start_y_position = 300.0;

    for row in 0..rows {
        for col in 0..cols {
            let brick_size = Size {
                width: 70.0,
                height: 30.0,
            };

            let x = start_x_position + (col as f32) * (brick_size.width + spacing);
            let y = start_y_position - (row as f32) * (brick_size.height + spacing);

            commands.spawn((
                Mesh2d(meshes.add(Rectangle::new(brick_size.width, brick_size.height))),
                MeshMaterial2d(materials.add(Color::srgb(255.0, 255.0, 255.0))),
                Transform::from_xyz(x, y, 0.0),
                brick_size,
                Brick,
            ));
        }
    }
}

fn move_player(
    mut players: Query<&mut Transform, With<Player>>,
    buttons: Res<ButtonInput<MouseButton>>,
    touches: Res<Touches>,
    windows: Query<&Window>,
    camera_query: Query<(&Camera, &GlobalTransform)>,
    time: Res<Time>,
) {
    let mut player = players.single_mut();
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

    let speed = 10.0;
    let alpha = (speed * time.delta_secs()).min(1.0);

    player.translation.x = player.translation.x + (final_position.x - player.translation.x) * alpha;
}

fn move_ball(mut balls: Query<(&mut Transform, &Velocity), With<Ball>>, time: Res<Time>) {
    let (mut ball, velo) = balls.single_mut();

    ball.translation.x += time.delta_secs() * velo.x;
    ball.translation.y += time.delta_secs() * velo.y;
}

fn check_collision_player(
    players: Query<(&Transform, &Size), With<Player>>,
    mut ball: Query<(&Transform, &mut Velocity, &Size), With<Ball>>,
) {
    let (player, player_size) = players.single();
    let (ball, mut ball_velocity, ball_size) = ball.single_mut();

    if ball.translation.x + ball_size.height > player.translation.x - player_size.width / 2.0
        && ball.translation.x - ball_size.height < player.translation.x + player_size.width / 2.0
        && ball.translation.y - ball_size.height < player.translation.y + player_size.height / 2.0
        && ball.translation.y - ball_size.height > player.translation.y - player_size.height / 2.0
    {
        ball_velocity.y = -ball_velocity.y;
    }
}

fn check_collision_bricks(
    mut commands: Commands,
    mut balls: Query<(&Transform, &mut Velocity, &Size), With<Ball>>,
    bricks: Query<(Entity,&Transform, &Size), With<Brick>>,
) {
    let (ball_transform, mut ball_velocity, ball_size) = balls.single_mut();


    for (brick_entity, brick_transform, brick_size) in bricks.iter() {
        let ball_left = ball_transform.translation.x - ball_size.width / 2.0;
        let ball_right = ball_transform.translation.x + ball_size.width / 2.0;
        let ball_top = ball_transform.translation.y + ball_size.height / 2.0;
        let ball_bottom = ball_transform.translation.y - ball_size.height / 2.0;

        let brick_left = brick_transform.translation.x - brick_size.width / 2.0;
        let brick_right = brick_transform.translation.x + brick_size.width / 2.0;
        let brick_top = brick_transform.translation.y + brick_size.height / 2.0;
        let brick_bottom = brick_transform.translation.y - brick_size.height / 2.0;

        if ball_right > brick_left
            && ball_left < brick_right
            && ball_top > brick_bottom
            && ball_bottom < brick_top
        {
            ball_velocity.y = -ball_velocity.y;
            commands.entity(brick_entity).despawn();
            break;
        }
    }
}

#[derive(Component)]
struct Player;

#[derive(Component)]
struct Brick;

#[derive(Component)]
struct Ball;

#[derive(Component)]
struct Velocity {
    x: f32,
    y: f32,
}

#[derive(Component)]
struct Size {
    width: f32,
    height: f32,
}
