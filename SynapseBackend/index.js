require('dotenv').config();
const express = require('express');
const { MongoClient } = require('mongodb');
const { HfInference } = require('@huggingface/inference');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
app.use(express.json());
app.use(cors());

// Wrap Express with HTTP Server for WebSockets
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const port = process.env.PORT || 3000;
const mongoUri = process.env.MONGODB_URI;
const hfToken = process.env.HF_TOKEN;

if (!mongoUri) {
    console.error("MONGODB_URI is not set. Please add it to your .env file.");
    process.exit(1);
}

if (!hfToken) {
    console.error("HF_TOKEN is not set. Please add it to your .env file.");
    process.exit(1);
}

const client = new MongoClient(mongoUri);
const hf = new HfInference(hfToken);
const databaseName = 'SynapseDB';

async function connectDB() {
    try {
        await client.connect();
        console.log("Connected to MongoDB Atlas!");
    } catch (err) {
        console.error("MongoDB Connection Error: ", err);
    }
}
connectDB();

async function generateEmbedding(text) {
    const response = await hf.featureExtraction({
        model: "sentence-transformers/all-MiniLM-L6-v2",
        inputs: text,
    });
    return response;
}

function buildAtlasSearchText(dossier) {
    const skills = Array.isArray(dossier.currentSkills) ? dossier.currentSkills.join(', ') : '';
    const interests = Array.isArray(dossier.futureInterests) ? dossier.futureInterests.join(', ') : '';
    return `Current skills: ${skills}. Future interests: ${interests}. Suggested role: ${dossier.suggestedRole}. Track mastery: ${dossier.trackMastery}/5.`;
}

app.post('/match', async (req, res) => {
    try {
        const dossier = req.body;

        if (!dossier.id || !Array.isArray(dossier.currentSkills) || !Array.isArray(dossier.futureInterests) || !dossier.suggestedRole) {
            return res.status(400).json({
                status: "error",
                message: "Invalid dossier payload"
            });
        }

        const searchText = buildAtlasSearchText(dossier);
        console.log(`Generating embedding for operative ${dossier.id}...`);
        const userEmbedding = await generateEmbedding(searchText);

        const database = client.db(databaseName);
        const profiles = database.collection('profiles');

        await profiles.updateOne(
            { id: dossier.id },
            {
                $set: {
                    ...dossier,
                    searchText,
                    embedding: userEmbedding,
                    updatedAt: new Date()
                }
            },
            { upsert: true }
        );

        console.log(`Searching for complementary peer via Atlas vector search...`);
        const agg = [
            {
                "$vectorSearch": {
                    "index": "default1",
                    "path": "embedding",
                    "queryVector": userEmbedding,
                    "numCandidates": 100,
                    "limit": 10,
                    "filter": {
                        "$and": [
                            { "suggestedRole": { "$ne": dossier.suggestedRole } },
                            { "id": { "$ne": dossier.id } }
                        ]
                    }
                }
            },
            {
                "$project": {
                    "embedding": 0,
                    "score": { "$meta": "searchScore" }
                }
            }
        ];

        const matchingPeers = await profiles.aggregate(agg).toArray();

        if (matchingPeers.length > 0) {
            const bestMatch = matchingPeers[0];
            res.json({
                status: "success",
                message: "Target secured.",
                peerId: bestMatch.id,
                peerRole: bestMatch.suggestedRole,
                peerSummary: `Role: ${bestMatch.suggestedRole}. Skills: ${(bestMatch.currentSkills || []).join(', ')}. Interests: ${(bestMatch.futureInterests || []).join(', ')}`,
                trackTopic: dossier.futureInterests[0] || "Prompt Engineering",
                matchScore: bestMatch.score
            });
        } else {
            res.json({
                status: "waiting",
                message: "Dossier stored in the matchmaking pool. Waiting for a complementary operative."
            });
        }

    } catch (err) {
        console.error("Matchmaking Error:", err);
        res.status(500).json({
            status: "error",
            message: "Matchmaking failed"
        });
    }
});

app.post('/forge', async (req, res) => {
    try {
        const moduleData = req.body;
        
        if (!moduleData.trackTopic || !Array.isArray(moduleData.clues)) {
            return res.status(400).json({ error: "Invalid module data" });
        }

        const database = client.db(databaseName);
        const modules = database.collection('modules');

        moduleData.upvotes = 0;
        moduleData.createdAt = new Date();

        await modules.insertOne(moduleData);

        res.json({
            status: "success",
            message: "Module forged and saved to community database!"
        });

    } catch (err) {
        console.error("Forge Error:", err);
        res.status(500).json({ error: "Failed to save forged module" });
    }
});

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on('joinRoom', ({ sessionId, userId }) => {
        socket.join(sessionId);
        console.log(`User ${userId} joined session ${sessionId}`);
        socket.to(sessionId).emit('playerJoined', { userId });
    });

    socket.on('revealClue', ({ sessionId, clueIndex }) => {
        console.log(`Clue ${clueIndex} revealed in session ${sessionId}`);
        io.to(sessionId).emit('clueRevealed', { clueIndex });
    });

    socket.on('submitAnswer', ({ sessionId, answer }) => {
        console.log(`Answer "${answer}" submitted in session ${sessionId}`);
        io.to(sessionId).emit('answerAttempted', { answer });
    });

    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id}`);
    });
});

server.listen(port, () => {
    console.log(`Synapse Matchmaker API & WebSockets running on port ${port}`);
});
