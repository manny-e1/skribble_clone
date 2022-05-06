import express from 'express';
import http from 'http';
import mongoose from 'mongoose';
import { Server } from 'socket.io';
import dotenv from 'dotenv';
import cors from 'cors';

dotenv.config();

const app = express();

const port = (process.env.PORT = 3000);

let server = http.createServer(app);

const io = new Server(server);

mongoose
  .connect(process.env.MONGO_URL)
  .then(() => {
    console.log('Connection succesfull');
  })
  .catch((e) => console.log(e));

app.use(cors());
app.use(express.json());

server.listen(port, '0.0.0.0', () => {
  console.log(`server running on port ${port}`);
});
