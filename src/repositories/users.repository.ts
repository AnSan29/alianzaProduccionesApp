// src/repositories/users.repository.ts
import User, {
  UserAttributes,
  UserCreationAttributes,
} from "../models/user.model";
import { FindOptions, Op } from "sequelize";

export class UsersRepository {
  static async findAll(offset = 0, limit = 20, search?: string) {
    const where: any = {};
    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
      ];
    }
    const { rows, count } = await User.findAndCountAll({
      where,
      offset,
      limit,
      order: [["id", "DESC"]],
    });
    return { rows, count };
  }

  static async findById(id: number) {
    return User.findByPk(id);
  }

  static async findByEmail(email: string) {
    return User.findOne({ where: { email } });
  }

  static async create(data: UserCreationAttributes) {
    return User.create(data);
  }

  static async update(id: number, data: Partial<UserAttributes>) {
    const user = await this.findById(id);
    if (!user) return null;
    await user.update(data);
    return user;
  }

  static async softDelete(id: number) {
    const user = await this.findById(id);
    if (!user) return null;
    await user.update({ is_active: false });
    return user;
  }
}
