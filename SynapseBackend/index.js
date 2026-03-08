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
const mongoUri = process.env.MONGODB_URI || "YOUR_MONGODB_ATLAS_URI";
const hfToken = process.env.HF_TOKEN || "YOUR_HUGGINGFACE_TOKEN";

const client = new MongoClient(mongoUri);
const hf = new HfInference(hfToken);

// Connect to MongoDB Atlas
async function connectDB() {
    try {
        await client.connect();
        console.log("Connected to MongoDB Atlas!");
    } catch (err) {
        console.error("MongoDB Connection Error: ", err);
    }
}
connectDB();

// HELPER: Generate vector embeddings from English text using an open HuggingFace model
async function generateEmbedding(text) {
    const response = await hf.featureExtraction({
        model: "sentence-transformers/all-MiniLM-L6-v2",
        inputs: text,
    });
    return response;
}

// POST /match
// Takes a fresh user bio, embeds it, and finds a COMPLEMENTARY peer
app.post('/match', async (req, res) => {
    try {
        const { userId, skills, interests, role, trackMastery } = req.body;
        
        if (!interests || !role) {
            return res.status(400).json({ error: "Missing interests or role for matchmaking" });
        }

        console.log(`Generating embedding for Operative ${userId} using Target Interests...`);
        // We only embed interests because we want a Vector Search for someone wanting to learn the SAME thing
        const userEmbedding = await generateEmbedding(interests);

        const database = client.db('SynapseDB');
        const profiles = database.collection('profiles');

        // 1. Save the new user's profile and embedding
        await profiles.updateOne(
            { userId: userId },
            { $set: { 
                skills, 
                interests, 
                primaryRole: role, 
                embedding: userEmbedding, 
                masteryLevel: trackMastery || 3 
            }},
            { upsert: true }
        );

        // 2. Perform $vectorSearch to find a complementary peer
        // The bio sent is a "Rich Profile String" (Skills + Future Interests + Mastery).
        // It maximizes semantic similarity on their target domains, while the filter isolates complementary roles.
        console.log(`Searching for complementary peer via Atlas Pipeline...`);
        const agg = [
            {
                "$vectorSearch": {
                    "index": "default1",
                    "path": "embedding",
                    "queryVector": userEmbedding,
                    "numCandidates": 100,
                    "limit": 5,
                    // The core hack: Finding common interests but filtering out people with the exact same role
                    "filter": { "primaryRole": { "$ne": role } }
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
                message: "Matched successfully!",
                peerId: bestMatch.userId,
                peerBio: `Role: ${bestMatch.primaryRole} | Skills: ${bestMatch.skills} | Interests: ${bestMatch.interests}`,
                matchScore: bestMatch.score,
                peerMastery: bestMatch.masteryLevel || 3
            });
        } else {
            res.json({
                status: "waiting",
                message: "Saved to matchmaking pool. Waiting for complementary peer."
            });
        }

    } catch (err) {
        console.error("Matchmaking Error:", err);
        res.status(500).json({ error: "Matchmaking failed" });
    }
});

// POST /forge
// Saves a Gemini-generated GameSession module to the community database
app.post('/forge', async (req, res) => {
    try {
        const moduleData = req.body;
        
        if (!moduleData.topic || !moduleData.clues) {
            return res.status(400).json({ error: "Invalid module data" });
        }

        const database = client.db('SynapseDB');
        const modules = database.collection('modules');

        // Add initial community upvotes
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

// --- WEB SOCKETS: ASYMMETRIC GAME LOBBY ---
io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // Join a specific game session room
    socket.on('joinRoom', ({ sessionId, userId }) => {
        socket.join(sessionId);
        console.log(`User ${userId} joined session ${sessionId}`);
        
        // Let the other player know someone joined
        socket.to(sessionId).emit('playerJoined', { userId });
    });

    // When the INTEL player reveals a clue
    socket.on('revealClue', ({ sessionId, clueIndex }) => {
        console.log(`Clue ${clueIndex} revealed in session ${sessionId}`);
        io.to(sessionId).emit('clueRevealed', { clueIndex });
    });

    // When the CONTROLS player submits an answer
    socket.on('submitAnswer', ({ sessionId, answer }) => {
        console.log(`Answer "${answer}" submitted in session ${sessionId}`);
        
        // In a real app we'd validate against the database, but for the hackathon
        // we bounce it back to both players so they can transition to the Debrief
        io.to(sessionId).emit('answerAttempted', { answer });
    });

    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id}`);
    });
});

server.listen(port, () => {
    console.log(`Synapse Matchmaker API & WebSockets running on port ${port}`);
});
