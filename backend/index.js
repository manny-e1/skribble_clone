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
});

server.listen(port, '0.0.0.0', () => {
  console.log(`server running on port ${port}`);
});
