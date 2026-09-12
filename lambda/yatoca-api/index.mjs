import { randomUUID } from "node:crypto";
import { DynamoDBClient, PutItemCommand, QueryCommand } from "@aws-sdk/client-dynamodb";

const client = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME ?? "yatoca-feedback";

const json = (statusCode, body) => ({
  statusCode,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  },
  body: JSON.stringify(body),
});

const parseJsonBody = (event) => {
  if (!event.body) return {};
  try {
    return JSON.parse(event.body);
  } catch {
    return null;
  }
};

const cleanString = (value, maxLength) => {
  if (typeof value !== "string") return null;
  const cleaned = value.trim();
  if (!cleaned) return null;
  return cleaned.slice(0, maxLength);
};

async function createHeroOpinion(event) {
  const body = parseJsonBody(event);
  if (!body) return json(400, { error: "JSON inválido" });

  const message = cleanString(body.message, 30);
  if (!message) return json(400, { error: "El mensaje es requerido" });

  const createdAt = new Date().toISOString();
  await client.send(new PutItemCommand({
    TableName: TABLE_NAME,
    Item: {
      pk: { S: "HERO" },
      sk: { S: `${createdAt}#${randomUUID()}` },
      comentario: { S: message },
      fecha: { S: createdAt },
      createdAt: { S: createdAt },
    },
  }));

  return json(200, {
    success: true,
    message: "Opinión guardada exitosamente",
    fecha: createdAt,
  });
}

async function listHeroOpinions() {
  const result = await client.send(new QueryCommand({
    TableName: TABLE_NAME,
    KeyConditionExpression: "pk = :pk",
    ExpressionAttributeValues: { ":pk": { S: "HERO" } },
    ScanIndexForward: false,
    Limit: 100,
  }));

  return json(200, {
    success: true,
    data: (result.Items ?? []).map((item) => ({
      comentario: item.comentario?.S ?? "",
      fecha: item.fecha?.S ?? item.createdAt?.S ?? "",
    })),
  });
}

async function createQuestionOpinion(event) {
  const body = parseJsonBody(event);
  if (!body) return json(400, { error: "JSON inválido" });

  const q1 = cleanString(body.q1, 2000);
  const q2 = cleanString(body.q2, 2000);
  const q3 = cleanString(body.q3, 2000);
  const ageGroup = cleanString(body.age_group, 20);

  if (![q1, q2, q3].some(Boolean)) {
    return json(400, { error: "Debe completar al menos una pregunta" });
  }

  const allowedAgeGroups = new Set(["16-29", "30-45", "46+"]);
  if (!ageGroup || !allowedAgeGroups.has(ageGroup)) {
    return json(400, { error: "Grupo de edad inválido" });
  }

  const createdAt = new Date().toISOString();
  const item = {
    pk: { S: "QUESTION" },
    sk: { S: `${createdAt}#${randomUUID()}` },
    age_group: { S: ageGroup },
    fecha: { S: createdAt },
    createdAt: { S: createdAt },
  };

  if (q1) item.q1 = { S: q1 };
  if (q2) item.q2 = { S: q2 };
  if (q3) item.q3 = { S: q3 };

  await client.send(new PutItemCommand({
    TableName: TABLE_NAME,
    Item: item,
  }));

  return json(200, {
    success: true,
    message: "Opinión guardada exitosamente",
    fecha: createdAt,
  });
}

export const handler = async (event) => {
  const method = event.requestContext?.http?.method ?? event.httpMethod;
  const path = event.rawPath ?? event.path ?? "";

  try {
    if (path === "/api/opiniones-hero" && method === "GET") {
      return await listHeroOpinions();
    }

    if (path === "/api/opiniones-hero" && method === "POST") {
      return await createHeroOpinion(event);
    }

    if (path === "/api/opiniones" && method === "POST") {
      return await createQuestionOpinion(event);
    }

    return json(404, { error: "Not found" });
  } catch (error) {
    console.error("Unhandled API error", error);
    return json(500, { error: "Error interno del servidor" });
  }
};
