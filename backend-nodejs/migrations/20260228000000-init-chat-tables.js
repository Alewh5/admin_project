'use strict';

module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.createTable('rooms', {
            id: {
                type: Sequelize.STRING,
                primaryKey: true,
                allowNull: false
            },
            firstName: {
                type: Sequelize.STRING,
                allowNull: true
            },
            lastName: {
                type: Sequelize.STRING,
                allowNull: true
            },
            email: {
                type: Sequelize.STRING,
                allowNull: true
            },
            reason: {
                type: Sequelize.STRING,
                allowNull: true
            },
            originUrl: {
                type: Sequelize.STRING,
                allowNull: true
            },
            status: {
                type: Sequelize.STRING,
                defaultValue: 'open'
            },
            agentId: {
                type: Sequelize.STRING,
                allowNull: true
            },
            agentName: {
                type: Sequelize.STRING,
                allowNull: true
            },
            createdAt: {
                allowNull: false,
                type: Sequelize.DATE
            },
            updatedAt: {
                allowNull: false,
                type: Sequelize.DATE
            }
        });

        await queryInterface.createTable('messages', {
            id: {
                type: Sequelize.INTEGER,
                autoIncrement: true,
                primaryKey: true,
                allowNull: false
            },
            roomId: {
                type: Sequelize.STRING,
                references: {
                    model: 'rooms',
                    key: 'id'
                },
                onUpdate: 'CASCADE',
                onDelete: 'CASCADE'
            },
            senderId: {
                type: Sequelize.STRING,
                allowNull: false
            },
            role: {
                type: Sequelize.STRING,
                allowNull: false
            },
            message: {
                type: Sequelize.TEXT,
                allowNull: true
            },
            type: {
                type: Sequelize.STRING,
                defaultValue: 'text'
            },
            fileUrl: {
                type: Sequelize.STRING,
                allowNull: true
            },
            createdAt: {
                allowNull: false,
                type: Sequelize.DATE
            },
            updatedAt: {
                allowNull: false,
                type: Sequelize.DATE
            }
        });
    },

    async down(queryInterface, Sequelize) {
        await queryInterface.dropTable('messages');
        await queryInterface.dropTable('rooms');
    }
};