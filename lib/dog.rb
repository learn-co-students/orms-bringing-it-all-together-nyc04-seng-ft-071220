require 'pry'

class Dog

attr_accessor :name, :breed, :id

def initialize(name:, breed:, id: nil)
    @id=id
    @name=name
    @breed=breed
end


#creates the dogs table in the database
def self.create_table
    sql= <<-SQL
    CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
    )
    SQL
    DB[:conn].execute(sql)
end

#drops the dogs table from database
def self.drop_table
    sql="DROP TABLE IF EXISTS dogs"
    DB[:conn].execute(sql)
end

#takes in a hash of attributes and uses metaprogramming to create a new dog object. 
#Then it uses the #save method to save that dog to the database returns a new dog object
def self.create(name:, breed:)
    dog=Dog.new(name: name, breed: breed)
    dog.save
    dog
end



# returns an instance of the dog class
# saves an instance of the dog class to the database 
# and then sets the given dogs `id` attribute
def save
    if self.id
        self.update
    else
    sql= <<-SQL
    INSERT INTO dogs(name, breed)
    VALUES(?, ?)
    SQL
  DB[:conn].execute(sql, self.name, self.breed)
    @id= DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
    end
    self
end



#creates an instance with corresponding attribute values
def self.new_from_db(row)
id=row[0]
name=row[1]
breed=row[2]
self.new(id: id, name: name, breed: breed) 
 # when dealing with key/value pairs in initialize method, include keys in arguments
end

#updates the record associated with a given instance
def update
    sql="UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
end

#returns an instance of dog that matches the name from the DB
def self.find_by_name(name)
    sql= <<-SQL
    SELECT * 
    FROM dogs
    WHERE name = ?
    LIMIT 1
    SQL
    DB[:conn].execute(sql, name).map do |row|
        self.new_from_db(row)
    end.first
end


# returns a new dog object by id
def self.find_by_id(id)
    sql= <<-SQL
    SELECT *
    FROM dogs
    WHERE id = ?
    LIMIT 1
    SQL

    DB[:conn].execute(sql, id).map do |row|
        self.new_from_db(row)
    end.first
end

# creates an instance of a dog if it does not already exist 
# when two dogs have the same name and different breed, 
#it returns the correct dog 
# when creating a new dog with the same name as persisted dogs, 
#it returns the correct dog
def self.find_or_create_by(name:, breed:)
   sql= <<-SQL
   SELECT * 
   FROM  dogs 
   WHERE name = ? 
   AND breed = ?
   LIMIT 1
   SQL
   
    dog=DB[:conn].execute(sql, name, breed)

    if !dog.empty?
        dog_data=dog[0]
        dog=Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
    else
        dog=self.create(name: name, breed: breed)
    end
    dog
end
end

