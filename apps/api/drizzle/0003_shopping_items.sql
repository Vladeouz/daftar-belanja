CREATE TABLE "shopping_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"name" text NOT NULL,
	"quantity" integer DEFAULT 1 NOT NULL,
	"is_done" boolean DEFAULT false NOT NULL,
	"created_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp (3) with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "shopping_items_name_length_check" CHECK (char_length("shopping_items"."name") between 1 and 80),
	CONSTRAINT "shopping_items_quantity_range_check" CHECK ("shopping_items"."quantity" between 1 and 999)
);
--> statement-breakpoint
ALTER TABLE "shopping_items" ADD CONSTRAINT "shopping_items_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "shopping_items_user_id_name_unique" ON "shopping_items" USING btree ("user_id",lower("name"));--> statement-breakpoint
CREATE INDEX "shopping_items_user_id_created_at_id_index" ON "shopping_items" USING btree ("user_id","created_at" DESC NULLS FIRST,"id" DESC NULLS FIRST);