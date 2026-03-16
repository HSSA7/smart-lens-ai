require('dotenv').config();
const fastify = require('fastify')({ logger: true });
const multipart = require('@fastify/multipart');
const axios = require('axios');
const FormData = require('form-data');

// --- NEW PRISMA 7 DRIVER ADAPTER SETUP ---
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

// 1. Set up the direct connection pool to PostgreSQL
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);

// 2. Hand the adapter to Prisma so it knows how to talk to the DB
const prisma = new PrismaClient({ adapter });
// -----------------------------------------

// Register the multipart plugin so Node can accept image files from the Mobile App
fastify.register(require('@fastify/multipart'), {
  limits: {
    fileSize: 10 * 1024 * 1024 // 10 Megabytes
  }
});
fastify.register(require('@fastify/cors'), { origin: '*' });
// 🚀 The Main Endpoint: This is what the Android/Flutter app will call!
fastify.post('/analyze-image', async (request, reply) => {
  try {
    // 1. Catch the image sent by the mobile app
    const data = await request.file();
    if (!data) {
      return reply.status(400).send({ error: "No image uploaded" });
    }
    const fileBuffer = await data.toBuffer();

    // 2. Database Magic: Find or create a 'demo_user' so we have someone to attach the image to
    let user = await prisma.user.findUnique({ where: { username: "demo_user" }});
    if (!user) {
      user = await prisma.user.create({
        data: { username: "demo_user", password: "securepassword123" }
      });
    }

    // 3. Package the image back up to send to the Python AI
    const form = new FormData();
    form.append('file', fileBuffer, data.filename);

    // 4. Send the image to the Python API (which is running on port 8000)
    console.log("Sending image to Python AI...");
    const pythonResponse = await axios.post('http://localhost:8000/analyze', form, {
      headers: { ...form.getHeaders() },
    });

    const aiResult = pythonResponse.data;

    if (aiResult.status === "success") {
      // 5. Save the exact result in our PostgreSQL database using Prisma
      console.log("Saving result to Database...");
      const savedRecord = await prisma.imageRecord.create({
        data: {
          userId: user.id,
          detectedObject: aiResult.detected_object,
          confidence: aiResult.confidence_percentage
        }
      });

      // 6. Send the final package back to the Mobile App!
      return reply.send({
        status: "success",
        message: "Analysis complete and saved to database!",
        database_record_id: savedRecord.id,
        ai_analysis: aiResult
      });
    } else {
      return reply.status(500).send({ error: "AI Engine failed to analyze the image." });
    }

  } catch (error) {
    fastify.log.error(error);
    return reply.status(500).send({ error: "Internal Server Error", details: error.message });
  }
});

// Start up the Node.js Server
const start = async () => {
  try {
    // Listen on port 3000
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
    console.log("⚡ Orchestrator is LIVE at http://localhost:3000");
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();