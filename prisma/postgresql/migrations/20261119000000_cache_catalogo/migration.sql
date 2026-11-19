CREATE TABLE "VersaoCatalogo" (
    "id" INTEGER NOT NULL,
    "versao" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "VersaoCatalogo_pkey" PRIMARY KEY ("id")
);
INSERT INTO "VersaoCatalogo" ("id", "versao") VALUES (1, 0);
