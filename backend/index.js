const express = require('express');
var http = require('http');
var server = http.createServer(app);
const mongoose = require('mongoose');
const Room = require('./models/Room');
var io = require('socket.io')(server);
const getWord = require('./api/getWord');

dotenv.config();

const app = express();

const port = (process.env.PORT = 3000);

let server = http.createServer(app);

const io = socket(server);

mongoose
  .connect(process.env.MONGO_URL)
  .then(() => {
    console.log('Connection succesfull');
  })
  .catch((e) => console.log(e));

app.use(cors());
app.use(express.json());

io.on('connection', (socket) => {
  console.log('connected');
  // CREATE GAME CALLBACK
  socket.on('create-game', async ({ nickname, name, occupancy, maxRounds }) => {
    try {
      const existingRoom = await Room.findOne({ name });
      if (existingRoom) {
        socket.emit('notCorrectGame', 'Room with that name already exists!');
        return;
      }
      let room = new Room();
      const word = getWord();
      room.word = word;
      room.name = name;
      room.occupancy = occupancy;
      room.maxRounds = maxRounds;

      let player = {
        socketID: socket.id,
        nickname,
        isPartyLeader: true,
      };
      room.players.push(player);
      room = await room.save();
      socket.join(name);
      io.to(name).emit('updateRoom', room);
    } catch (err) {
      console.log(err);
    }
  });

  socket.on('join-game', async ({ nickname, name }) => {
    try {
      let room = await Room.findOne({ name });
      if (!room) {
        socket.emit('notCorrectGame', 'Please enter a valid room name');
        return;
      }

      if (room.isJoin) {
        let player = {
          socketID: socket.id,
          nickname,
        };
        room.players.push(player);
        socket.join(name);

        if (room.players.length === room.occupancy) {
          room.isJoin = false;
        }
        room.turn = room.players[room.turnIndex];
        room = await room.save();
        io.to(name).emit('updateRoom', room);
      } else {
        socket.emit(
          'notCorrectGame',
          'The game is in progress, please try later!'
        );
      }
    } catch (err) {
      console.log(err);
    }
  });

  socket.on('msg', async (data) => {
    console.log(data);
    try {
      if (data.msg === data.word) {
        let room = await Room.find({ name: data.roomName });
        let userPlayer = room[0].players.filter(
          (player) => player.nickname === data.username
        );
        if (data.timeTaken !== 0) {
          userPlayer[0].points += Math.round((200 / data.timeTaken) * 10);
        }
        room = await room[0].save();
        io.to(data.roomName).emit('msg', {
          username: data.username,
          msg: 'Guessed it!',
          guessedUserCtr: data.guessedUserCtr + 1,
        });
        socket.emit('closeInput', '');
      } else {
        io.to(data.roomName).emit('msg', {
          username: data.username,
          msg: data.msg,
          guessedUserCtr: data.guessedUserCtr,
        });
      }
    } catch (err) {
      console.log(err.toString());
    }
  });

  socket.on('change-turn', async (name) => {
    try {
      let room = await Room.findOne({ name });
      let idx = room.turnIndex;
      if (idx + 1 === room.players.length) {
        room.currentRound += 1;
      }
      if (room.currentRound <= room.maxRounds) {
        const word = getWord();
        room.word = word;
        room.turnIndex = (idx + 1) % room.players.length;
        room.turn = room.players[room.turnIndex];
        room = await room.save();
        io.to(name).emit('change-turn', room);
      } else {
        io.to(name).emit('show-leaderboard', room.players);
      }
    } catch (err) {
      console.log(err);
    }
  });

  socket.on('updateScore', async (name) => {
    try {
      const room = await Room.findOne({ name });
      io.to(name).emit('updateScore', room);
    } catch (err) {
      console.log(err);
    }
  });

  socket.on('paint', ({ details, roomName }) => {
    io.to(roomName).emit('points', { details: details });
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`server running on port ${port}`);
});
